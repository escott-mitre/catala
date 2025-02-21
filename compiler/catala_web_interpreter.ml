open Catala_utils
open Driver
open Js_of_ocaml

let _ =
  Js.export_all
    (object%js
       method interpret
           (contents : Js.js_string Js.t)
           (scope : Js.js_string Js.t)
           (language : Js.js_string Js.t)
           (trace : bool) =
         driver `Interpret
           (Contents (Js.to_string contents))
           {
             Cli.debug = false;
             color = Never;
             wrap_weaved_output = false;
             avoid_exceptions = false;
             plugins_dirs = [];
             language = Some (Js.to_string language);
             max_prec_digits = None;
             closure_conversion = false;
             message_format = Human;
             trace;
             disable_warnings = true;
             disable_counterexamples = false;
             optimize = false;
             check_invariants = false;
             ex_scope = Some (Js.to_string scope);
             ex_variable = None;
             output_file = None;
             print_only_law = false;
             link_modules = [];
           }
    end)
