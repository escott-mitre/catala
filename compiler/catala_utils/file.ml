(* This file is part of the Catala compiler, a specification language for tax
   and social benefits computation rules. Copyright (C) 2020 Inria, contributor:
   Emile Rolley <emile.rolley@tuta.io>, Louis Gesbert <louis.gesbert@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

(** Run finaliser [f] unconditionally after running [k ()], propagating any
    raised exception. *)
let finally f k =
  match k () with
  | exception e ->
    let bt = Printexc.get_raw_backtrace () in
    f ();
    Printexc.raise_with_backtrace e bt
  | r ->
    f ();
    r

let temp_file pfx sfx =
  let f = Filename.temp_file pfx sfx in
  if not !Cli.debug_flag then
    at_exit (fun () -> try Sys.remove f with _ -> ());
  f

let with_out_channel filename f =
  let oc = open_out filename in
  finally (fun () -> close_out oc) (fun () -> f oc)

let with_in_channel filename f =
  let oc = open_in filename in
  finally (fun () -> close_in oc) (fun () -> f oc)

let with_formatter_of_out_channel oc f =
  let fmt = Message.formatter_of_out_channel oc in
  finally (fun () -> Format.pp_print_flush fmt ()) @@ fun () -> f fmt

let with_formatter_of_file filename f =
  with_out_channel filename (fun oc -> with_formatter_of_out_channel oc f)

let with_formatter_of_opt_file filename_opt f =
  match filename_opt with
  | None -> finally (fun () -> flush stdout) (fun () -> f Format.std_formatter)
  | Some filename -> with_formatter_of_file filename f

let get_out_channel ~source_file ~output_file ?ext () =
  match output_file, ext with
  | Some "-", _ | None, None -> None, fun f -> f stdout
  | Some f, _ -> Some f, with_out_channel f
  | None, Some ext ->
    let src =
      match source_file with Pos.FileName f -> f | Pos.Contents _ -> "a"
    in
    let f = Filename.remove_extension src ^ ext in
    Some f, with_out_channel f

let get_formatter_of_out_channel ~source_file ~output_file ?ext () =
  let f, with_ = get_out_channel ~source_file ~output_file ?ext () in
  f, fun fmt -> with_ (fun oc -> with_formatter_of_out_channel oc fmt)

let with_temp_file pfx sfx ?contents f =
  let filename = temp_file pfx sfx in
  finally (fun () -> Sys.remove filename)
  @@ fun () ->
  Option.iter
    (fun contents ->
      with_out_channel filename (fun oc -> output_string oc contents))
    contents;
  f filename

let contents filename =
  with_in_channel filename (fun ic ->
      really_input_string ic (in_channel_length ic))

let process_out ?check_exit cmd args =
  let check_exit =
    let default n =
      if n <> 0 then
        Printf.ksprintf failwith "Sub-process %s returned with status %d" cmd n
    in
    Option.value check_exit ~default
  in
  let aargs = Array.of_list (cmd :: args) in
  let ic =
    try Unix.open_process_args_in cmd aargs
    with Unix.Unix_error (Unix.ENOENT, _, _) ->
      Printf.ksprintf failwith "ERROR: program %s not found" cmd
  in
  let buf = Buffer.create 4096 in
  finally (fun () ->
      match Unix.close_process_in ic with
      | Unix.WEXITED n -> check_exit n
      | Unix.WSIGNALED n | Unix.WSTOPPED n ->
        Printf.ksprintf failwith "Sub-process %s was killed (%d)" cmd n)
  @@ fun () ->
  try
    while true do
      Buffer.add_channel buf ic 4096
    done;
    assert false
  with End_of_file -> Buffer.contents buf
