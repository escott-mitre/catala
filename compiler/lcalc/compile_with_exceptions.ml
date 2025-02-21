(* This file is part of the Catala compiler, a specification language for tax
   and social benefits computation rules. Copyright (C) 2020 Inria, contributor:
   Denis Merigoux <denis.merigoux@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

open Catala_utils
open Shared_ast
module D = Dcalc.Ast
module A = Ast

type 'm ctx = unit
(** This translation no longer needs a context at the moment, but we keep
    passing the argument through the functions in case the need arises with
    further evolutions. *)

let thunk_expr (type m) (e : m A.expr boxed) : m A.expr boxed =
  let dummy_var = Var.make "_" in
  let pos = Expr.pos e in
  let arg_t = Mark.add pos (TLit TUnit) in
  Expr.make_abs [| dummy_var |] e [arg_t] pos

let translate_var : 'm D.expr Var.t -> 'm A.expr Var.t = Var.translate

let rec translate_default
    (ctx : 'm ctx)
    (exceptions : 'm D.expr list)
    (just : 'm D.expr)
    (cons : 'm D.expr)
    (mark_default : 'm mark) : 'm A.expr boxed =
  let exceptions =
    List.map (fun except -> thunk_expr (translate_expr ctx except)) exceptions
  in
  let pos = Expr.mark_pos mark_default in
  let exceptions =
    Expr.make_app
      (Expr.eop Op.HandleDefault
         [TAny, pos; TAny, pos; TAny, pos]
         (Expr.no_mark mark_default))
      [
        Expr.earray exceptions mark_default;
        thunk_expr (translate_expr ctx just);
        thunk_expr (translate_expr ctx cons);
      ]
      pos
  in
  exceptions

and translate_expr (ctx : 'm ctx) (e : 'm D.expr) : 'm A.expr boxed =
  let m = Mark.get e in
  match Mark.remove e with
  | EEmptyError -> Expr.eraise EmptyError m
  | EErrorOnEmpty arg ->
    Expr.ecatch (translate_expr ctx arg) EmptyError
      (Expr.eraise NoValueProvided m)
      m
  | EDefault { excepts = [exn]; just; cons } when !Cli.optimize_flag ->
    (* FIXME: bad place to rely on a global flag *)
    Expr.ecatch (translate_expr ctx exn) EmptyError
      (Expr.eifthenelse (translate_expr ctx just) (translate_expr ctx cons)
         (Expr.eraise EmptyError (Mark.get e))
         (Mark.get e))
      (Mark.get e)
  | EDefault { excepts; just; cons } ->
    translate_default ctx excepts just cons (Mark.get e)
  | EOp { op; tys } -> Expr.eop (Operator.translate op) tys m
  | ( ELit _ | EApp _ | EArray _ | EVar _ | EExternal _ | EAbs _ | EIfThenElse _
    | ETuple _ | ETupleAccess _ | EInj _ | EAssert _ | EStruct _
    | EStructAccess _ | EMatch _ ) as e ->
    Expr.map ~f:(translate_expr ctx) (Mark.add m e)
  | _ -> .

let rec translate_scope_lets
    (decl_ctx : decl_ctx)
    (ctx : 'm ctx)
    (scope_lets : 'm D.expr scope_body_expr) :
    'm A.expr scope_body_expr Bindlib.box =
  match scope_lets with
  | Result e ->
    Bindlib.box_apply (fun e -> Result e) (Expr.Box.lift (translate_expr ctx e))
  | ScopeLet scope_let ->
    let scope_let_var, scope_let_next =
      Bindlib.unbind scope_let.scope_let_next
    in
    let new_scope_let_expr = translate_expr ctx scope_let.scope_let_expr in
    let new_scope_next = translate_scope_lets decl_ctx ctx scope_let_next in
    let new_scope_next =
      Bindlib.bind_var (translate_var scope_let_var) new_scope_next
    in
    Bindlib.box_apply2
      (fun new_scope_next new_scope_let_expr ->
        ScopeLet
          {
            scope_let_typ = scope_let.scope_let_typ;
            scope_let_kind = scope_let.scope_let_kind;
            scope_let_pos = scope_let.scope_let_pos;
            scope_let_next = new_scope_next;
            scope_let_expr = new_scope_let_expr;
          })
      new_scope_next
      (Expr.Box.lift new_scope_let_expr)

let translate_items
    (decl_ctx : decl_ctx)
    (ctx : 'm ctx)
    (scopes : 'm D.expr code_item_list) : 'm A.expr code_item_list Bindlib.box =
  Scope.map_ctx
    ~f:
      (fun ctx -> function
        | Topdef (name, ty, e) ->
          ( ctx,
            Bindlib.box_apply
              (fun e -> Topdef (name, ty, e))
              (Expr.Box.lift (translate_expr ctx e)) )
        | ScopeDef (name, body) ->
          let scope_input_var, body_expr =
            Bindlib.unbind body.scope_body_expr
          in
          let new_scope_body_expr =
            translate_scope_lets decl_ctx ctx body_expr
          in
          let new_body =
            Bindlib.bind_var (translate_var scope_input_var) new_scope_body_expr
          in
          ( ctx,
            Bindlib.box_apply
              (fun scope_body_expr ->
                ScopeDef (name, { body with scope_body_expr }))
              new_body ))
    ~varf:translate_var ctx scopes

let translate_program (prgm : 'm D.program) : 'm A.program =
  {
    code_items =
      Bindlib.unbox (translate_items prgm.decl_ctx () prgm.code_items);
    decl_ctx = prgm.decl_ctx;
  }
