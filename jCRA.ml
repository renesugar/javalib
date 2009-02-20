(*
 *  This file is part of JavaLib
 *  Copyright (c)2007-2008 Université de Rennes 1 / CNRS
 *  Tiphaine Turpin <first.last@irisa.fr>
 *  Laurent Hubert <first.last@irisa.fr>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

open JBasics
open JClass
open JProgram


let add_methods dictionary mm =
  let imap = ref MethodMap.empty
  and f m =
    match m with
      | JClass.AbstractMethod m -> AbstractMethod (cam2pam dictionary m)
      | JClass.ConcreteMethod m -> ConcreteMethod (
	  let m = (ccm2pcm dictionary m) in m.cm_has_been_parsed <- true;
	    m) in
    JClass.MethodMap.iter
      (fun ms m ->
	 let msi = dictionary.get_ms_index ms in
	   imap := MethodMap.add msi (f m) !imap) mm;
    !imap

let add_amethods dictionary mm =
  let imap = ref MethodMap.empty
  and f m = cam2pam dictionary m in
    JClass.MethodMap.iter
      (fun ms m ->
	 let msi = dictionary.get_ms_index ms in
	   imap := MethodMap.add msi (f m) !imap) mm;
    !imap

let add_fields dictionary fm =
  let imap = ref FieldMap.empty in
    JClass.FieldMap.iter
      (fun fs cf ->
	 let fsi = dictionary.get_fs_index fs in
	   imap := FieldMap.add fsi cf !imap) fm;
    !imap

let add_classFile c classes dictionary =
  let imap =
    List.fold_left
      (fun imap iname ->
	 let iname_index = dictionary.get_cn_index iname in
	 let i =
	   try
	     match ClassMap.find iname_index classes with
		 | `Interface i -> i
		 | `Class _ ->
		     raise (Class_structure_error
			      (JDumpBasics.class_name c.JClass.c_name^" is declared to implements "
			       ^JDumpBasics.class_name iname^", which is a class and not an interface."))
	   with Not_found -> raise (Class_not_found iname)
	 in ClassMap.add iname_index i imap
      )
      ClassMap.empty
      c.JClass.c_interfaces
  in let c_super =
    match c.JClass.c_super_class with
      | None -> None
      | Some super ->
	  let super_index = dictionary.get_cn_index super in
	    try
	      match ClassMap.find super_index classes with
		| `Class c -> Some c
		| `Interface _ ->
		    raise (Class_structure_error
			     (JDumpBasics.class_name c.JClass.c_name^" is declared to extends "
			      ^JDumpBasics.class_name super^", which is an interface and not a class."))
	    with Not_found -> raise (Class_not_found super)
  in
  let c' =
    {c_name = c.JClass.c_name;
     c_index = dictionary.get_cn_index c.JClass.c_name;
     c_version = c.JClass.c_version;
     c_access = c.JClass.c_access;
     c_generic_signature = c.JClass.c_generic_signature;
     c_final = c.JClass.c_final;
     c_abstract = c.JClass.c_abstract;
     c_synthetic = c.JClass.c_synthetic;
     c_enum = c.JClass.c_enum;
     c_other_flags = c.JClass.c_other_flags;
     c_super_class = c_super;
     c_consts = c.JClass.c_consts;
     c_interfaces = imap;
     c_sourcefile = c.JClass.c_sourcefile;
     c_deprecated = c.JClass.c_deprecated;
     c_enclosing_method = c.JClass.c_enclosing_method;
     c_source_debug_extention =c.JClass.c_source_debug_extention;
     c_inner_classes = c.JClass.c_inner_classes;
     c_other_attributes = c.JClass.c_other_attributes;
     c_fields = add_fields dictionary c.JClass.c_fields;
     c_methods = add_methods dictionary c.JClass.c_methods;
     c_resolve_methods = MethodMap.empty;
     c_may_be_instanciated = true;
     c_children = ClassMap.empty;}
  in
  let c_index' = dictionary.get_cn_index c'.c_name in
    MethodMap.iter
      (fun ms _ -> declare_method (`Class c') ms)
      c'.c_methods;
    ClassMap.iter
      (fun _ i ->
	 i.i_children_class <- ClassMap.add c_index' c' i.i_children_class)
      c'.c_interfaces;
    begin
      match super_class (`Class c') with
	| None -> ();
	| Some parent ->
	    parent.c_children <- ClassMap.add c_index' c' parent.c_children
    end;
    ClassMap.add c_index' (`Class c') classes

let add_interfaceFile c classes dictionary =
  let imap =
    List.fold_left
      (fun imap iname ->
	 let iname_index = dictionary.get_cn_index iname in
	 let i =
	   try
	     match ClassMap.find iname_index classes with
	       | `Interface i -> i
	       | `Class c' ->
		   raise (Class_structure_error
			    ("Interface "^JDumpBasics.class_name c.JClass.i_name^" is declared to extends "
			     ^JDumpBasics.class_name c'.c_name^", which is an interface and not a class."))
	   with Not_found -> raise (Class_not_found iname)
	 in ClassMap.add iname_index i imap
      )
      ClassMap.empty
      c.JClass.i_interfaces
  and super =
    try match ClassMap.find java_lang_object_index classes with
      | `Class c -> c
      | `Interface _ ->
	  raise (Class_structure_error"java.lang.Object is declared as an interface.")
    with Not_found -> raise (Class_not_found java_lang_object)
  in
  let c' =
    {i_name = c.JClass.i_name;
     i_index = dictionary.get_cn_index c.JClass.i_name;
     i_version = c.JClass.i_version;
     i_access = c.JClass.i_access;
     i_generic_signature = c.JClass.i_generic_signature;
     i_consts = c.JClass.i_consts;
     i_annotation = c.JClass.i_annotation;
     i_other_flags = c.JClass.i_other_flags;
     i_interfaces = imap;
     i_sourcefile = c.JClass.i_sourcefile;
     i_deprecated = c.JClass.i_deprecated;
     i_source_debug_extention = c.JClass.i_source_debug_extention;
     i_inner_classes = c.JClass.i_inner_classes;
     i_other_attributes = c.JClass.i_other_attributes;
     i_children_interface = ClassMap.empty;
     i_children_class = ClassMap.empty;
     i_super = super;
     i_initializer =
	begin
	  match c.JClass.i_initializer with
	    | None -> None
	    | Some m -> Some (ccm2pcm dictionary m)
	end;
     i_fields = add_fields dictionary c.JClass.i_fields;
     i_methods = add_amethods dictionary c.JClass.i_methods;
    }
  in
  let c_index' = dictionary.get_cn_index c'.i_name in
    MethodMap.iter
      (fun ms _ -> declare_method (`Interface c') ms)
      c'.i_methods;
    ClassMap.iter
      (fun _ i ->
	i.i_children_interface <- ClassMap.add c_index' c' i.i_children_interface)
      c'.i_interfaces;
    ClassMap.add c_index' (`Interface c') classes


let add_one_file f classes dictionary = match f with
  | `Interface i -> add_interfaceFile i classes dictionary
  | `Class c -> add_classFile c classes dictionary

let add_class_referenced c dictionary classmap to_add =
  Array.iter
    (function
      | ConstMethod (TClass cn,_,_)
      | ConstInterfaceMethod (cn,_,_)
      | ConstField (cn,_,_)
      | ConstValue (ConstClass (TClass cn))
	-> let cni = (dictionary.get_cn_index cn) in
	  if not (ClassMap.mem cni classmap) then to_add := cn::!to_add
      | _ -> ())
    (JClass.get_consts c)

let get_class class_path dictionary class_map name =
  let name_index = dictionary.get_cn_index name in
    try ClassMap.find name_index !class_map
    with Not_found ->
      try
	let c = JFile.get_class class_path (JDumpBasics.class_name name)
	in
	  class_map := ClassMap.add name_index c !class_map;
	  c;
      with No_class_found _ -> raise (Class_not_found name)

let rec add_file class_path c classes dictionary =
  let classmap = ref ClassMap.empty in
  let to_add = ref [] in
  let classes =
    try
      let c_index = dictionary.get_cn_index (JClass.get_name c) in
	if not (ClassMap.mem c_index classes)
	then
	  begin
	    add_class_referenced c dictionary !classmap to_add;
	    add_one_file c classes dictionary
	  end
	else classes
    with Class_not_found cn ->
      let missing_class = get_class class_path dictionary classmap cn in
	add_file class_path c
	  (add_file class_path missing_class classes dictionary) dictionary
  in begin
      let p_classes = ref classes in
	try while true do
	  let cn = List.hd !to_add in
	    to_add := List.tl !to_add;
	    if not (ClassMap.mem (dictionary.get_cn_index cn) !p_classes)
	    then
	      let c = get_class class_path dictionary classmap cn
	      in p_classes := add_file class_path c !p_classes dictionary
	done;
	  !p_classes
	with Failure "hd" -> !p_classes
    end

let parse_program class_path names =
  (* build a map of all the JClass.class_file that are going to be
     translated to build the new hierarchy.*)
  let (jars,others) = List.partition (fun f -> Filename.check_suffix f ".jar") names in
  let p_dic = make_dictionary () in
  let class_map =
    JFile.read
      class_path
      (fun cmap c ->
	 let c_index = p_dic.get_cn_index (JClass.get_name c) in
	   ClassMap.add c_index c cmap)
      ClassMap.empty
      jars in
  let class_path = JFile.class_path class_path in
  let class_map = ref
    begin
      List.fold_left
	(fun clmap cn ->
	   let c = JFile.get_class class_path cn in
	   let c_index = p_dic.get_cn_index (JClass.get_name c) in
	     ClassMap.add c_index c clmap)
	class_map
	others
    end in
  let p_classes =
    ClassMap.fold
      (fun _ c classes -> add_file class_path c classes p_dic)
      !class_map ClassMap.empty
  in
    JFile.close_class_path class_path;
    { classes = p_classes;
      static_lookup = (fun _ _ _ -> failwith "static lookup not Implemented for JCRA");
      dictionary = p_dic }