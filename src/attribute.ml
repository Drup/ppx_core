open Asttypes
open Parsetree

module String_set = Set.Make(String)
module String_map = Map.Make(String)

let white_list =
  List.fold_left
    (fun acc name -> Name.fold_dot_suffixes name ~init:acc ~f:String_set.add)
    String_set.empty
    [ "ocaml.error"
    ; "ocaml.warning"
    ; "ocaml.deprecated"
    ; "ocaml.doc"
    ; "ocaml.text"
    ; "nonrec"
    ]
;;

let check_not_reserved name =
  if String_set.mem name white_list then
    Printf.ksprintf failwith
      "Cannot register attribute with name '%s' as it matches an \
       attribute reserved by the compiler"
      name
;;

let poly_equal a b =
  let module Poly = struct
    type t = T : _ -> t
  end in
  Poly.T a = Poly.T b
;;

module Context = struct
  type 'a t =
    | Label_declaration       : label_declaration       t
    | Constructor_declaration : constructor_declaration t
    | Type_declaration        : type_declaration        t
    | Type_extension          : type_extension          t
    | Extension_constructor   : extension_constructor   t
    | Pattern                 : pattern                 t
    | Core_type               : core_type               t
    | Expression              : expression              t
    | Value_description       : value_description       t
    | Class_type              : class_type              t
    | Class_type_field        : class_type_field        t
    | Class_infos             : _ class_infos           t
    | Class_expr              : class_expr              t
    | Class_field             : class_field             t
    | Module_type             : module_type             t
    | Module_declaration      : module_declaration      t
    | Module_type_declaration : module_type_declaration t
    | Open_description        : open_description        t
    | Include_infos           : _ include_infos         t
    | Module_expr             : module_expr             t
    | Value_binding           : value_binding           t
    | Module_binding          : module_binding          t
    | Pstr_eval               : structure_item          t
    | Pstr_extension          : structure_item          t
    | Psig_extension          : signature_item          t

  let label_declaration       = Label_declaration
  let constructor_declaration = Constructor_declaration
  let type_declaration        = Type_declaration
  let type_extension          = Type_extension
  let extension_constructor   = Extension_constructor
  let pattern                 = Pattern
  let core_type               = Core_type
  let expression              = Expression
  let value_description       = Value_description
  let class_type              = Class_type
  let class_type_field        = Class_type_field
  let class_infos             = Class_infos
  let class_expr              = Class_expr
  let class_field             = Class_field
  let module_type             = Module_type
  let module_declaration      = Module_declaration
  let module_type_declaration = Module_type_declaration
  let open_description        = Open_description
  let include_infos           = Include_infos
  let module_expr             = Module_expr
  let value_binding           = Value_binding
  let module_binding          = Module_binding
  let pstr_eval               = Pstr_eval
  let pstr_extension          = Pstr_extension
  let psig_extension          = Psig_extension

  let get_pstr_eval st =
    match st.pstr_desc with
    | Pstr_eval (e, l) -> (e, l)
    | _ -> failwith "Attribute.Context.get_pstr_eval"

  let get_pstr_extension st =
    match st.pstr_desc with
    | Pstr_extension (e, l) -> (e, l)
    | _ -> failwith "Attribute.Context.get_pstr_extension"

  let get_psig_extension st =
    match st.psig_desc with
    | Psig_extension (e, l) -> (e, l)
    | _ -> failwith "Attribute.Context.get_psig_extension"

  let get_attributes : type a. a t -> a -> attributes = fun t x ->
    match t with
    | Label_declaration       -> x.pld_attributes
    | Constructor_declaration -> x.pcd_attributes
    | Type_declaration        -> x.ptype_attributes
    | Type_extension          -> x.ptyext_attributes
    | Extension_constructor   -> x.pext_attributes
    | Pattern                 -> x.ppat_attributes
    | Core_type               -> x.ptyp_attributes
    | Expression              -> x.pexp_attributes
    | Value_description       -> x.pval_attributes
    | Class_type              -> x.pcty_attributes
    | Class_type_field        -> x.pctf_attributes
    | Class_infos             -> x.pci_attributes
    | Class_expr              -> x.pcl_attributes
    | Class_field             -> x.pcf_attributes
    | Module_type             -> x.pmty_attributes
    | Module_declaration      -> x.pmd_attributes
    | Module_type_declaration -> x.pmtd_attributes
    | Open_description        -> x.popen_attributes
    | Include_infos           -> x.pincl_attributes
    | Module_expr             -> x.pmod_attributes
    | Value_binding           -> x.pvb_attributes
    | Module_binding          -> x.pmb_attributes
    | Pstr_eval               -> snd (get_pstr_eval      x)
    | Pstr_extension          -> snd (get_pstr_extension x)
    | Psig_extension          -> snd (get_psig_extension x)

  let set_attributes : type a. a t -> a -> attributes -> a = fun t x attrs ->
    match t with
    | Label_declaration       -> { x with pld_attributes    = attrs }
    | Constructor_declaration -> { x with pcd_attributes    = attrs }
    | Type_declaration        -> { x with ptype_attributes  = attrs }
    | Type_extension          -> { x with ptyext_attributes = attrs }
    | Extension_constructor   -> { x with pext_attributes   = attrs }
    | Pattern                 -> { x with ppat_attributes   = attrs }
    | Core_type               -> { x with ptyp_attributes   = attrs }
    | Expression              -> { x with pexp_attributes   = attrs }
    | Value_description       -> { x with pval_attributes   = attrs }
    | Class_type              -> { x with pcty_attributes   = attrs }
    | Class_type_field        -> { x with pctf_attributes   = attrs }
    | Class_infos             -> { x with pci_attributes    = attrs }
    | Class_expr              -> { x with pcl_attributes    = attrs }
    | Class_field             -> { x with pcf_attributes    = attrs }
    | Module_type             -> { x with pmty_attributes   = attrs }
    | Module_declaration      -> { x with pmd_attributes    = attrs }
    | Module_type_declaration -> { x with pmtd_attributes   = attrs }
    | Open_description        -> { x with popen_attributes  = attrs }
    | Include_infos           -> { x with pincl_attributes  = attrs }
    | Module_expr             -> { x with pmod_attributes   = attrs }
    | Value_binding           -> { x with pvb_attributes    = attrs }
    | Module_binding          -> { x with pmb_attributes    = attrs }
    | Pstr_eval ->
      { x with pstr_desc = Pstr_eval      (get_pstr_eval x      |> fst, attrs) }
    | Pstr_extension ->
      { x with pstr_desc = Pstr_extension (get_pstr_extension x |> fst, attrs) }
    | Psig_extension ->
      { x with psig_desc = Psig_extension (get_psig_extension x |> fst, attrs) }

  let desc : type a. a t -> string = function
    | Label_declaration       -> "label declaration"
    | Constructor_declaration -> "constructor declaration"
    | Type_declaration        -> "type declaration"
    | Type_extension          -> "type extension"
    | Extension_constructor   -> "extension constructor"
    | Pattern                 -> "pattern"
    | Core_type               -> "core type"
    | Expression              -> "expression"
    | Value_description       -> "value"
    | Class_type              -> "class type"
    | Class_type_field        -> "class type field"
    | Class_infos             -> "class declaration"
    | Class_expr              -> "class expression"
    | Class_field             -> "class field"
    | Module_type             -> "module type"
    | Module_declaration      -> "module declaration"
    | Module_type_declaration -> "module type declaration"
    | Open_description        -> "open"
    | Include_infos           -> "include"
    | Module_expr             -> "module expression"
    | Value_binding           -> "value binding"
    | Module_binding          -> "module binding"
    | Pstr_eval               -> "toplevel expression"
    | Pstr_extension          -> "toplevel extension"
    | Psig_extension          -> "toplevel signature extension"

(*
  let pattern : type a b c d. a t
    -> (attributes, b, c) Ast_pattern.t
    -> (a, c, d) Ast_pattern.t
    -> (a, b, d) Ast_pattern.t = function
    | Label_declaration       -> Ast_pattern.pld_attributes
    | Constructor_declaration -> Ast_pattern.pcd_attributes
    | Type_declaration        -> Ast_pattern.ptype_attributes
    | Type_extension          -> Ast_pattern.ptyext_attributes
    | Extension_constructor   -> Ast_pattern.pext_attributes
*)

  let equal : _ t -> _ t -> bool = poly_equal
end

module Floating_context = struct
  type 'a t =
    | Structure_item   : structure_item   t
    | Signature_item   : signature_item   t
    | Class_field      : class_field      t
    | Class_type_field : class_type_field t

  let structure_item   = Structure_item
  let signature_item   = Signature_item
  let class_field      = Class_field
  let class_type_field = Class_type_field

  let get_attribute_if_is_floating_node : type a. a t -> a -> attribute option
    = fun t x ->
      match t, x with
      | Structure_item   , { pstr_desc = Pstr_attribute a; _ } -> Some a
      | Signature_item   , { psig_desc = Psig_attribute a; _ } -> Some a
      | Class_field      , { pcf_desc  = Pcf_attribute  a; _ } -> Some a
      | Class_type_field , { pctf_desc = Pctf_attribute a; _ } -> Some a
      | _ -> None

  let get_attribute t x =
    match get_attribute_if_is_floating_node t x with
    | Some a -> a
    | None   -> failwith "Attribute.Floating.Context.get_attribute"

  let replace_by_dummy : type a. a t -> a -> a =
    let dummy_ext = ({ txt = ""; loc = Location.none }, PStr []) in
    fun t x ->
    match t with
    | Structure_item   -> { x with pstr_desc = Pstr_extension (dummy_ext, []) }
    | Signature_item   -> { x with psig_desc = Psig_extension (dummy_ext, []) }
    | Class_field      -> { x with pcf_desc  = Pcf_extension   dummy_ext      }
    | Class_type_field -> { x with pctf_desc = Pctf_extension  dummy_ext      }

  let desc : type a. a t -> string = function
    | Structure_item   -> "structure item"
    | Signature_item   -> "signature item"
    | Class_field      -> "class field"
    | Class_type_field -> "class type field"

  let equal : _ t -> _ t -> bool = poly_equal
end

type packed_context =
  | On_item  : _ Context.t          -> packed_context
  | Floating : _ Floating_context.t -> packed_context

type ('a, 'b) t =
  { name    : string
  ; context : 'a Context.t
  ; payload : (Parsetree.payload, 'b) Ast_pattern.Packed.t
  }

type packed = T : (_, _) t -> packed

let registrar =
  Name.Registrar.create
    ~kind:"attribute"
    ~current_file:__FILE__
    ~string_of_context:(function
      | On_item  t -> Some (Context         .desc t)
      | Floating t -> Some (Floating_context.desc t ^ " (floating)"))
;;

let declare name context pattern k =
  check_not_reserved name;
  Name.Registrar.register registrar (On_item context) name;
  { name
  ; context
  ; payload = Ast_pattern.Packed.create pattern k
  }
;;

module Phys_table = Hashtbl.Make(struct
    type t = string
    let hash = Hashtbl.hash
    let equal = ( == )
  end)

let not_seen = Phys_table.create 128

let mark_as_seen attr =
  let name = (fst attr).txt in
  Phys_table.remove not_seen name
;;

let mark_as_handled_manually = mark_as_seen

let get_internal =
  let rec find_best_match t attributes longest_match =
    match attributes with
    | [] -> longest_match
    | (name, _) as attr :: rest ->
      if Name.matches ~pattern:t.name name.txt then begin
        match longest_match with
        | None -> find_best_match t rest (Some attr)
        | Some (name', _) ->
          let len = String.length name.txt in
          let len' = String.length name'.txt in
          if len > len' then
            find_best_match t rest (Some attr)
          else if len < len' then
            find_best_match t rest longest_match
          else
            Location.raise_errorf ~loc:name.loc "Duplicated attribute"
      end else
        find_best_match t rest longest_match
  in
  fun t attributes ->
    find_best_match t attributes None
;;

let convert pattern attr =
  mark_as_seen attr;
  Ast_pattern.Packed.parse pattern (Common.loc_of_payload attr) (snd attr)
;;

let get t x =
  let attrs = Context.get_attributes t.context x in
  match get_internal t attrs with
  | None -> None
  | Some attr -> Some (convert t.payload attr)
;;

let consume t x =
  let attrs = Context.get_attributes t.context x in
  match get_internal t attrs with
  | None -> None
  | Some attr ->
    let attrs = List.filter (fun attr' -> not (attr == attr')) attrs in
    let x = Context.set_attributes t.context x attrs in
    Some (x, convert t.payload attr)
;;

let remove_seen (type a) (context : a Context.t) packeds (x : a) =
  let attrs = Context.get_attributes context x in
  let matched =
    let rec loop acc = function
      | [] -> acc
      | T t :: rest ->
        if Context.equal t.context context then
          match get_internal t attrs with
          | None      -> loop acc rest
          | Some attr ->
            let name = (fst attr).txt in
            if Phys_table.mem not_seen name then
              loop acc rest
            else
              loop (attr :: acc) rest
        else
          loop acc rest
    in
    loop [] packeds
  in
  let attrs = List.filter (fun attr' -> not (List.memq attr' matched)) attrs in
  Context.set_attributes context x attrs
;;

let pattern t p =
  let f = Ast_pattern.to_func p in
  Ast_pattern.of_func (fun ctx loc x k ->
    match consume t x with
    | None        -> f ctx loc x (k None)
    | Some (x, v) -> f ctx loc x (k (Some v))
  )
;;

module Floating = struct
  module Context = Floating_context

  type ('a, 'b) t =
    { name    : string
    ; context : 'a Context.t
    ; payload : (Parsetree.payload, 'b) Ast_pattern.Packed.t
    }

  let declare name context pattern k =
    check_not_reserved name;
    Name.Registrar.register registrar (Floating context) name;
    { name; context; payload = Ast_pattern.Packed.create pattern k }
  ;;

  let convert ts x =
    match ts with
    | [] -> None
    | { context; _ } :: _ ->
      assert (List.for_all (fun t -> Context.equal t.context context) ts);
      let attr = Context.get_attribute context x in
      let name = fst attr in
      match List.filter (fun t -> Name.matches ~pattern:t.name name.txt) ts with
      | [] -> None
      | [t] -> Some (convert t.payload attr)
      | l ->
        Location.raise_errorf ~loc:name.loc
          "Multiple match for floating attributes: %s"
          (String.concat ", " (List.map (fun t -> t.name) l))
  ;;
end

let check_attribute registrar context name =
  if not (String_set.mem name.txt white_list) then
    let white_list = String_set.elements white_list in
    Name.Registrar.raise_errorf registrar context ~white_list
      "Attribute `%s' was not used" name
;;

let check_unused = object(self)
  inherit Ast_traverse.iter as super

  method! attribute (name, _) =
    Location.raise_errorf ~loc:name.loc
      "attribute not expected here, Ppx_core.Std.Attribute needs updating!"

  method private check_node : type a. a Context.t -> a -> a = fun context node ->
    let attrs = Context.get_attributes context node in
    match attrs with
    | [] -> node
    | _  ->
      List.iter
        (fun ((name, payload) as attr) ->
           self#payload payload;
           check_attribute registrar (On_item context) name;
           (* If we allow the attribute to pass through, mark it as seen *)
           mark_as_seen attr)
        attrs;
      Context.set_attributes context node []

  method private check_floating : type a. a Floating.Context.t -> a -> a
    = fun context node ->
      match Floating.Context.get_attribute_if_is_floating_node context node with
      | None -> node
      | Some  ((name, payload) as attr) ->
        self#payload payload;
        check_attribute registrar (Floating context) name;
        mark_as_seen attr;
        Floating.Context.replace_by_dummy context node

  method! label_declaration       x = super#label_declaration       (self#check_node Context.Label_declaration       x)
  method! constructor_declaration x = super#constructor_declaration (self#check_node Context.Constructor_declaration x)
  method! type_declaration        x = super#type_declaration        (self#check_node Context.Type_declaration        x)
  method! type_extension          x = super#type_extension          (self#check_node Context.Type_extension          x)
  method! extension_constructor   x = super#extension_constructor   (self#check_node Context.Extension_constructor   x)
  method! pattern                 x = super#pattern                 (self#check_node Context.Pattern                 x)
  method! core_type               x = super#core_type               (self#check_node Context.Core_type               x)
  method! expression              x = super#expression              (self#check_node Context.Expression              x)
  method! value_description       x = super#value_description       (self#check_node Context.Value_description       x)
  method! class_type              x = super#class_type              (self#check_node Context.Class_type              x)
  method! class_infos f           x = super#class_infos f           (self#check_node Context.Class_infos             x)
  method! class_expr              x = super#class_expr              (self#check_node Context.Class_expr              x)
  method! module_type             x = super#module_type             (self#check_node Context.Module_type             x)
  method! module_declaration      x = super#module_declaration      (self#check_node Context.Module_declaration      x)
  method! module_type_declaration x = super#module_type_declaration (self#check_node Context.Module_type_declaration x)
  method! open_description        x = super#open_description        (self#check_node Context.Open_description        x)
  method! include_infos f         x = super#include_infos f         (self#check_node Context.Include_infos           x)
  method! module_expr             x = super#module_expr             (self#check_node Context.Module_expr             x)
  method! value_binding           x = super#value_binding           (self#check_node Context.Value_binding           x)
  method! module_binding          x = super#module_binding          (self#check_node Context.Module_binding          x)

  method! class_field x =
    let x = self#check_node              Context.Class_field x in
    let x = self#check_floating Floating.Context.Class_field x in
    super#class_field x

  method! class_type_field x =
    let x = self#check_node              Context.Class_type_field x in
    let x = self#check_floating Floating.Context.Class_type_field x in
    super#class_type_field x

  method! structure_item item =
    let item = self#check_floating Floating.Context.Structure_item item in
    let item =
      match item.pstr_desc with
      | Pstr_eval      _ -> self#check_node Context.Pstr_eval      item
      | Pstr_extension _ -> self#check_node Context.Pstr_extension item
      | _                -> item
    in
    super#structure_item item

  method! signature_item item =
    let item = self#check_floating Floating.Context.Signature_item item in
    let item =
      match item.psig_desc with
      | Psig_extension _ -> self#check_node Context.Psig_extension item
      | _                -> item
    in
    super#signature_item item
end

let freshen_and_collect = object
  inherit Ast_traverse.map as super

  method! attribute ((name, payload) as attr) =
    let loc = Common.loc_of_attribute attr in
    let payload = super#payload payload in
    let key = String.copy name.txt in
    let name = { name with txt = key } in
    Phys_table.add not_seen key loc;
    (name, payload)
end

let check_all_seen () =
  let fail name loc =
    Location.raise_errorf ~loc "Attribute `%s' was silently dropped" name
  in
  Phys_table.iter fail not_seen
;;

let remove_attributes_present_in table = object
  inherit Ast_traverse.iter as super

  method! attribute (name, payload) =
    super#payload payload;
    Phys_table.remove table name.txt
end

let copy_of_not_seen () =
  let copy = Phys_table.create (Phys_table.length not_seen) in
  Phys_table.iter (Phys_table.add copy) not_seen;
  copy
;;

let dropped_so_far_structure st =
  let table = copy_of_not_seen () in
  (remove_attributes_present_in table)#structure st;
  Phys_table.fold (fun txt loc acc -> { txt; loc } :: acc) table []
;;

let dropped_so_far_signature sg =
  let table = copy_of_not_seen () in
  (remove_attributes_present_in table)#signature sg;
  Phys_table.fold (fun txt loc acc -> { txt; loc } :: acc) table []
;;
