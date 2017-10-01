Require Import HoTT.
Require Import Family.
Require Import ShapeSystems.
Require Import Coproduct.
Require Import DeductiveClosure.
Require Import RawSyntax.
Require Import SignatureMaps.

Section Raw_Rules.

  Context {σ : Shape_System}.
  Context (Σ : Signature σ).

  Record Raw_Rule
  :=
    { RR_metas : Arity _
    ; RR_prem : Family (Judgt_Instance (Metavariable_Extension Σ RR_metas))
    ; RR_concln : (Judgt_Instance (Metavariable_Extension Σ RR_metas))
    }.

  Definition CCs_of_RR (R : Raw_Rule)
    : Family (closure_condition (Judgt_Instance Σ)).
  Proof.
    exists { Γ : Raw_Context Σ & Instantiation (RR_metas R) Σ Γ }.
    intros [Γ I].
    split.
    - (* premises *)
      refine (Fmap _ (RR_prem R)).
      apply (instantiate_ji I).
    - apply (instantiate_ji I).
      apply (RR_concln R).
  Defined.

  Definition Raw_Type_Theory := Family Raw_Rule.

End Raw_Rules.

Arguments CCs_of_RR {_ _} _.

(* TODO: probably split this file up, to separate the specifications from the truly raw rules/type theories? *)

(** Specification of “well-shaped” rules *)
Section RuleSpecs.

Context {Proto_Cxt : Shape_System}.

(* The parameters of a rule-spec, beyond its ambient signature, may be a little counter-intuitive.  The point is that they are just what is required to determine the arity of the symbol introduced by the rule, if it’s an object rule. *)
Record Rule_Spec
  {Σ : Signature Proto_Cxt}
  {a : Arity Proto_Cxt} (* arity listing the _object_ premises of the rule *)
  {γ_conclusion : Shape Proto_Cxt} (* proto-context of the conclusion *)
  {hjf_conclusion : Hyp_Judgt_Form} (* judgement form of the conclusion *)
:=
  {
  (* The arity [a] supplies the family of object-judgment premises. *)
  (* The family of equality-judgment premises: *)
    RS_equality_premise : Arity Proto_Cxt
  (* family indexing the premises of the rule, and giving for each… *)
  ; RS_Premise : Family (Hyp_Judgt_Form * Proto_Cxt)
    := Family.Sum
         (Family.Fmap (fun cl_γ => (obj_HJF (fst cl_γ), snd cl_γ)) a)
         (Family.Fmap (fun cl_γ => (eq_HJF (fst cl_γ), snd cl_γ)) RS_equality_premise)
  (* - the judgement form of each premise, e.g. “term” or “type equality” *)
  ; RS_hjf_of_premise : RS_Premise -> Hyp_Judgt_Form
    := fun i => fst (RS_Premise i)
  (* - the proto-context of each premise *)
  ; RS_proto_cxt_of_premise : RS_Premise -> Proto_Cxt
    := fun i => snd (RS_Premise i)
  (* the ordering relation on the premises *)
  (* TODO: somewhere we will want to add that this is well-founded; maybe prop_valued; mayb more *)
  ; RS_lt : RS_Premise -> RS_Premise -> Type
  (* for each premise, the arity specifying what metavariables are available in the syntax for this premise; i.e., the family of type/term arguments already introduced by earlier premises *)
  ; RS_arity_of_premise : RS_Premise -> Arity _
    := fun i => Subfamily a (fun j => RS_lt (inl j) i)
  (* syntactic part of context of premise *)
  (* NOTE: this should never be used directly, always through [RS_raw_context_of_premise] *)
  ; RS_context_expr_of_premise 
    : forall (i : RS_Premise) (v : RS_proto_cxt_of_premise i),
        Raw_Syntax
          (Metavariable_Extension Σ (RS_arity_of_premise i))
          Ty
          (RS_proto_cxt_of_premise i)
  (* raw context of each premise *)
  ; RS_raw_context_of_premise
    : forall i : RS_Premise,
        Raw_Context (Metavariable_Extension Σ (RS_arity_of_premise i))
    := fun i => Build_Raw_Context _ (RS_context_expr_of_premise i)
  (* hypothetical judgement boundary instance for each premise *)
  ; RS_hyp_bdry_instance_of_premise
    : forall i : RS_Premise,
        Hyp_Judgt_Bdry_Instance
          (Metavariable_Extension Σ (RS_arity_of_premise i))
          (RS_hjf_of_premise i)
          (RS_proto_cxt_of_premise i)
  (* arity of the rule as a whole.  TODO: move out of definition! *)
  ; RS_arity : Arity _
    := Fmap
        (fun jγ => (class_of_HJF (fst jγ), snd jγ))
        (Subfamily RS_Premise
          (fun j => is_obj_HJF (fst (RS_Premise j))))
  (* judgement form of conclusion *)
  ; RS_hjf_of_conclusion : Hyp_Judgt_Form
    := hjf_conclusion
  (* context expressions of conclusion *)
  (* NOTE: this should never be used directly, always through [RS_raw_context_of_conclusion] *)
  ; RS_context_expr_of_conclusion
    : γ_conclusion -> Raw_Syntax (Metavariable_Extension Σ a) Ty γ_conclusion
  (* raw context of conclusion *)
  ; RS_raw_context_of_conclusion : Raw_Context (Metavariable_Extension Σ a)
    := Build_Raw_Context _ RS_context_expr_of_conclusion
  (* hyp judgement boundary instance of conclusion *)
  ; RS_hyp_judgt_bdry_instance_of_conclusion
      : Hyp_Judgt_Bdry_Instance
          (Metavariable_Extension Σ a)
          RS_hjf_of_conclusion
          γ_conclusion
  (* full judgement boundary instance of conclusion *)
  ; RS_judgt_bdry_instance_of_conclusion
      : Judgt_Bdry_Instance (Metavariable_Extension Σ a)
                            (HJF RS_hjf_of_conclusion)
    := (RS_raw_context_of_conclusion; RS_hyp_judgt_bdry_instance_of_conclusion)
  }.
  (* NOTE 1. One could restrict rule-specs by only allowing the case where the context of the conclusion is empty.  This would simplify this definition, and several things below, and would (one expects) not lose any generality, since one can always move variables from that context to become extra premises, giving an equivalent rule with empty conclusion context.

  However, we retain (for now) the current general version, (a) since rules are sometimes written this way in practice, and (b) to allow a precise theorem stating the claim above about it being equivalent to move variables into the premises. *)

  (* NOTE 2. Perhaps the parameters of the definition could be profitably abstracted into a “proto-rule-spec” (probably including also the arity [RS_equality_Premise]), fitting the pattern of the stratificaiton of objects into proto ≤ raw ≤ typed. *)

  Arguments Rule_Spec _ _ _ _ : clear implicits.

(* Template for defining rule-specs:

  simple refine (Build_Rule_Spec _ _ _ _ _ _ _ _ _ _).
  - admit. (* RS_equality_premise: arity of equality premises *)
  - admit. (* RS_lt *)
  - admit. (* RS_context_expr_of_premise *)
  - admit. (* RS_hyp_bdry_instance_of_premise *)
  - admit. (* RS_context_expr_of_conclusion *)
  - admit. (* RS_hyp_judgt_bdry_instance_of_conclusion *)

*)

  Definition Fmap_Rule_Spec
      {Σ} {Σ'} (f : Signature_Map Σ Σ')
      {a} {γ_concl} {hjf_concl}
      (R : Rule_Spec Σ a γ_concl hjf_concl)
    : Rule_Spec Σ' a γ_concl hjf_concl.
  Proof.
    simple refine (Build_Rule_Spec Σ' a γ_concl hjf_concl _ _ _ _ _ _).
    - exact (RS_equality_premise R).
    - exact (RS_lt R).
    - (* RS_context_expr_of_premise *)
      intros i v.
      refine (_ (RS_context_expr_of_premise R i v)).
      apply Fmap_Raw_Syntax, Fmap1_Metavariable_Extension, f.
    - (* RS_hyp_bdry_instance_of_premise *)
      intros i.
      simple refine 
        (Fmap_Hyp_Judgt_Bdry_Instance
          _ (RS_hyp_bdry_instance_of_premise R i)).
      apply Fmap1_Metavariable_Extension, f.
    - (* RS_context_expr_of_conclusion *)
      intros v.
      refine (_ (RS_context_expr_of_conclusion R v)).
      apply Fmap_Raw_Syntax, Fmap1_Metavariable_Extension, f.
    - (* RS_hyp_judgt_bdry_instance_of_conclusion *)
      simple refine 
        (Fmap_Hyp_Judgt_Bdry_Instance
          _ (RS_hyp_judgt_bdry_instance_of_conclusion R)).
      apply Fmap1_Metavariable_Extension, f.
  Defined.

End RuleSpecs.

Arguments Rule_Spec {_} _ _ _ _.

(** Specification of a type theory (but before checking that syntax in rules is well-typed. *)

Section TTSpecs.

  Context {σ : Shape_System}.

  Record Type_Theory_Spec
  := {
  (* The family of _rules_, with their object-premise arities and conclusion forms specified *)
    TTS_Rule : Family (Hyp_Judgt_Form * Arity σ * Shape σ)
  (* the judgement form of the conclusion of each rule *)
  ; TTS_hjf_of_rule : TTS_Rule -> Hyp_Judgt_Form
    := fun i => fst (fst (TTS_Rule i))
  (* the arity of the arguments (i.e. the *object* premises only) of each rule *)
  ; TTS_arity_of_rule : TTS_Rule -> Arity _
    := fun i => snd (fst (TTS_Rule i))
  (* the shape of the conclusion of each rule *)
  ; TTS_concl_shape_of_rule : TTS_Rule -> Shape σ
    := fun i => snd (TTS_Rule i)
  (* the ordering on rules.  TODO: will probably need to add well-foundedness. QUESTION: any reason for it to be Prop-valued, or could we just let it be type-valued? *)
  ; TTS_lt : TTS_Rule -> TTS_Rule -> hProp
  (* the signature over which each rule can be written *)
  ; TTS_signature_of_rule : TTS_Rule -> Signature σ
    := fun i => Fmap
        (fun jaγ => ( class_of_HJF (fst (fst jaγ))
                   , Family.Sum (snd (fst jaγ)) (simple_arity (snd jaγ))))
        (Subfamily TTS_Rule
          (fun j => is_obj_HJF (TTS_hjf_of_rule j) * TTS_lt j i))
  (* the actual rule specification of each rule *)
  ; TTS_rule_spec
    : forall i : TTS_Rule,
        Rule_Spec
          (TTS_signature_of_rule i)
          (TTS_arity_of_rule i)
          (TTS_concl_shape_of_rule i)
          (TTS_hjf_of_rule i)
  }.

  Definition Signature_of_TT_Spec (T : Type_Theory_Spec)
    : Signature σ.
  Proof.
    (* symbols are given by the object-judgement rules of T *)
    exists {r : TTS_Rule T & is_obj_HJF (TTS_hjf_of_rule _ r)}.
    intros r_H. set (r := pr1 r_H).
    split.
    - exact (class_of_HJF (TTS_hjf_of_rule _ r)).
    - exact (TTS_arity_of_rule _ r
            + simple_arity (TTS_concl_shape_of_rule _ r)).
  Defined.
    (* NOTE: it is tempting to case-analyse here and say 
      “when r is an object rule, use [(class_of_HJF …, TTS_arity_of_rule …)];
       in case r is an equality rule, use reductio ad absurdum with Hr.” 
     But we get stronger reduction behaviour by just taking [(class_of_HJF …, TTS_arity_of_rule …)] without case-analysing first.  (And up to equality, we get the same result.)  *)

  Definition TT_Spec_signature_inclusion_of_rule
      {T : Type_Theory_Spec} (r : TTS_Rule T)
    : Signature_Map (TTS_signature_of_rule _ r) 
                    (Signature_of_TT_Spec T).
  Proof.
    simple refine (_;_).
    - intros s_isob_lt.
      exact (pr1 s_isob_lt ; fst (pr2 (s_isob_lt))).
      (* TODO: introduce access functions for the signature components above? *)
    - intros s. exact idpath.
  Defined.

End TTSpecs.

Arguments Type_Theory_Spec _ : clear implicits.
Arguments TTS_Rule {_} _.
Arguments TTS_hjf_of_rule {_ _} _.
Arguments TTS_arity_of_rule {_ _} _.
Arguments TTS_concl_shape_of_rule {_ _} _.
Arguments TTS_lt {_ _} _ _.
Arguments TTS_signature_of_rule {_ _} _.
Arguments TTS_rule_spec {_ _} _.

(* Each rule-spec induces one or two raw rules: the logical rule itself, and (if it was an object rule) its associated congruence rule.*)

Section Raw_Rules_of_Rule_Specs.

  Context {σ : Shape_System}.
  Context {Σ : Signature σ}.

  (* Translating a rule-spec into a raw rule requires no extra information in the case of an equality-rule; in the case of an object-rule, it requires a symbol of appropriate arity to give the object introduced. *)
  Definition Raw_Rule_of_Rule_Spec
    {a} {γ_concl} {hjf_concl}
    (R : Rule_Spec Σ a γ_concl hjf_concl)
    (Sr : is_obj_HJF hjf_concl
        -> { S : Σ & (arity S = Family.Sum a (simple_arity γ_concl))
                     * (class S = class_of_HJF hjf_concl) })
  : Raw_Rule Σ.
  (* This construction involves essentially two aspects:
  - translate the syntax of each expression in the rule-spec from its “local” signatures to the overall signature;
  - reconstruct the head terms of the object premises and the conclusion *)
  Proof.
    refine (Build_Raw_Rule _ a _ _).
    - (* premises *)
      exists (RS_Premise R).
      intros P. 
      assert (f_P : Signature_Map
              (Metavariable_Extension Σ (RS_arity_of_premise R P))
              (Metavariable_Extension Σ a)).
      {
        apply Fmap2_Metavariable_Extension.
        apply Subfamily_inclusion.
      }
      exists (HJF (RS_hjf_of_premise _ P)).
      exists (Fmap_Raw_Context f_P (RS_raw_context_of_premise _ P)).
      simpl.
      apply Hyp_Judgt_Instance_from_bdry_plus_head.
      + refine (Fmap_Hyp_Judgt_Bdry_Instance f_P _).
        apply RS_hyp_bdry_instance_of_premise.
      + intro H_obj.
        destruct P as [ P | P ]; simpl in P.
        * (* case: P an object premise *)
          refine (symb_raw (inr P : Metavariable_Extension Σ a) _).
          intro i. apply var_raw.
          exact (coproduct_inj1 shape_is_coproduct i).
        * (* case: P an equality premise *)
          destruct H_obj. (* ruled out by assumption *)
    - (* conclusion *)
      exists (HJF hjf_concl).
      simpl.
      exists (pr1 (RS_judgt_bdry_instance_of_conclusion R)).
      apply Hyp_Judgt_Instance_from_bdry_plus_head.
      + exact (pr2 (RS_judgt_bdry_instance_of_conclusion R)).
      + intros H_obj.
        destruct hjf_concl as [ ocl | ecl ]; simpl in *.
        * (* case: R an object rule *)
          destruct (Sr tt) as [S_R [e_a e_cl]]. clear Sr H_obj.
          destruct e_cl.
          refine (symb_raw (inl S_R : Metavariable_Extension _ _) _).
          change (arity (inl S_R : Metavariable_Extension _ _))
            with (arity S_R). 
          set (aR := arity S_R) in *. destruct (e_a^); clear e_a.
          intros [P | i].
          -- cbn in P.
            refine (symb_raw (inr P : Metavariable_Extension _ _) _).
            intros i.
            apply var_raw.
            apply (coproduct_inj1 shape_is_coproduct).
            exact (coproduct_inj2 shape_is_coproduct i).
          -- apply var_raw.
            exact (coproduct_inj1 shape_is_coproduct i).
        * (* case: R an equality rule *)
          destruct H_obj. (* ruled out by assumption *)
  Defined.


  Definition associated_original_premise {obs eqs : Arity σ}
    : (obs + obs) + (eqs + eqs + obs) -> (obs + eqs).
  Proof.
    intros p ; repeat destruct p as [p | p];
      try exact (inl p); exact (inr p).
  Defined.
  
  Arguments associated_original_premise : simpl nomatch.

  (* The ordering of premises of the congruence rule_spec associated to an object rule_spec. 

  TODO: perhaps try to refactor to avoid so many special cases?  E.g. as: take the lex product of the input relation [R] with the 3-element order ({{0},{1},{0,1}}, ⊂ ) and then pull this back along the suitable map (o+o)+(e+e+o) —> (o+e)*3 ?  *)
  Definition associated_congruence_rule_lt
      {obs eqs : Type} (lt : relation (obs + eqs))
    : relation ((obs + obs) + (eqs + eqs + obs)).
  Proof.
  (*  In a more readable organisation, the cases we want are as follows:

           ob_l i   ob_r i   eq_l i   eq_r i   eq_new i

ob_l j     i < j    0        i < j    0        0

ob_r j     0        i < j    0        i < j    0
 
eq_l j     i < j    0        i < j    0        0

eq_r j     0        i < j    0        i < j    0

eq_new j   i ≤ j    i ≤ j    i < j    i < j    i < j

*)
    intros [ [ ob_l | ob_r ] | [ [ eq_l | eq_r ] | eq_new ] ];
    intros [ [ ob'_l | ob'_r ] | [ [ eq'_l | eq'_r ] | eq'_new ] ].
      (* column eq_l *)
    - exact (lt (inl ob_l) (inl ob'_l)).
    - exact False.
    - exact (lt (inl ob_l) (inr eq'_l)).
    - exact False.
    - exact ((lt (inl ob_l) (inl eq'_new)) \/ (ob_l = eq'_new)).
      (* column ob_r *)
    - exact False.
    - exact (lt (inl ob_r) (inl ob'_r)).
    - exact False.
    - exact (lt (inl ob_r) (inr eq'_r)).
    - exact ((lt (inl ob_r) (inl eq'_new)) \/ (ob_r = eq'_new)).
      (* column eq_l *)
    - exact (lt (inr eq_l) (inl ob'_l)).
    - exact False.
    - exact (lt (inr eq_l) (inr eq'_l)).
    - exact False.
    - exact (lt (inr eq_l) (inl eq'_new)).
      (* column eq_r *)
    - exact False.
    - exact (lt (inr eq_r) (inl ob'_r)).
    - exact False.
    - exact (lt (inr eq_r) (inr eq'_r)).
    - exact (lt (inr eq_r) (inl eq'_new)).
      (* column eq_new *)
    - exact False.
    - exact False.
    - exact False.
    - exact False.
    - exact (lt (inl eq_new) (inl eq'_new)).
  Defined.

  Arguments associated_congruence_rule_lt : simpl nomatch.

  Definition associated_congruence_rule_original_constructor_translation
    {a} {γ_concl} {hjf_concl} (R : Rule_Spec Σ a γ_concl hjf_concl)
    (p : (a + a) + (RS_equality_premise R + RS_equality_premise R + a))
    : Signature_Map
        (Metavariable_Extension Σ
          (RS_arity_of_premise R (associated_original_premise p)))
        (Metavariable_Extension Σ (Subfamily (a + a)
           (fun j => associated_congruence_rule_lt (RS_lt R) (inl j) p))).
  Proof.
    (* In case [p] is one of the 2 copies of the original premises, there is a single canonical choice for this definition.

    In case [p] is one of the new equality premises (between the 2 copies of the old equality premises), there are in principle 2 possibilities; it should make no difference which one chooses. *)
      destruct p as [ [ pob_l | pob_r ] | [ [ peq_l | peq_r ] | peq_new ] ].
      - (* pob_l *)
        simple refine (_;_).
        + intros [s | q].
          * exact (inl s). 
          * refine (inr _). exists (inl (pr1 q)). exact (pr2 q).
        + intros [? | ?]; exact idpath. 
      - (* pob_r *) 
        simple refine (_;_).
        + intros [s | q].
          * exact (inl s). 
          * refine (inr _). exists (inr (pr1 q)). exact (pr2 q).
        + intros [? | ?]; exact idpath. 
      - (* peq_l *) 
        simple refine (_;_).
        + intros [s | q].
          * exact (inl s). 
          * refine (inr _). exists (inl (pr1 q)). exact (pr2 q).
        + intros [? | ?]; exact idpath. 
      - (* peq_r *) 
        simple refine (_;_).
        + intros [s | q].
          * exact (inl s). 
          * refine (inr _). exists (inr (pr1 q)). exact (pr2 q).
        + intros [? | ?]; exact idpath. 
      - (* peq_new *)
        simple refine (_;_).
        + intros [s | q].
          * exact (inl s). 
          * refine (inr _).
            exists (inr (pr1 q)). (* note both [inl], [inr] make this work *)
            cbn; cbn in q. exact (inl (pr2 q)).
        + intros [? | ?]; exact idpath.         
  Defined.

  (* TODO: move *)
  (* Useful, with [idpath] as the equality argument, when want wants to construct the smybol argument interactively — this is difficult with original [symb_raw] due to [class S] appearing in the conclusion. *)
  Definition symb_raw' {Σ' : Signature σ}
      {γ} {cl} (S : Σ') (e : class S = cl)
      (args : forall i : arity S,
        Raw_Syntax Σ' (arg_class i) (shape_coproduct γ (arg_pcxt i)))
    : Raw_Syntax Σ' cl γ.
  Proof.
    destruct e.
    apply symb_raw; auto.
  Defined.

  Definition associated_congruence_rule_spec
    {a} {γ_concl} {hjf_concl} (R : Rule_Spec Σ a γ_concl hjf_concl)
    (H : is_obj_HJF hjf_concl)
    (S : Σ)
    (e_a : arity S = a + (simple_arity γ_concl))
    (e_cl : class S = class_of_HJF hjf_concl)
    : (Rule_Spec Σ (Family.Sum a a) γ_concl
                 (eq_HJF (class_of_HJF hjf_concl))).
  Proof.
    simple refine (Build_Rule_Spec _ _ _ _ _ _ _ _ _ _).
    - (* RS_equality_premise: arity of equality premises *)
      exact (((RS_equality_premise R) + (RS_equality_premise R)) + a). 
    - (* RS_lt *)
      exact (associated_congruence_rule_lt (RS_lt R)).
    - (* RS_context_expr_of_premise *)
      intros p i.
      refine (Fmap_Raw_Syntax
        (associated_congruence_rule_original_constructor_translation _ _) _).
      set (p_orig := associated_original_premise p).
      destruct p as [ [ ? | ? ] | [ [ ? | ? ] | ? ] ];
      refine (RS_context_expr_of_premise R p_orig i).
      (* alternatively, instead of destructing [p], could use equality reasoning on the type of [i]. *)
    - (* RS_hyp_bdry_instance_of_premise *)
      intros p.
      set (p_orig := associated_original_premise p).
      destruct p as [ [ ? | ? ] | [ [ ? | ? ] | p ] ];
      try (refine (Fmap_Hyp_Judgt_Bdry_Instance
        (associated_congruence_rule_original_constructor_translation _ _) _);
           refine (RS_hyp_bdry_instance_of_premise R p_orig)).
      (* The cases where [p] is a copy of an original premise are all just translation,
      leaving just the new equality premises to give. *)
      intros i; simpl Hyp_Judgt_Bdry_Slots in i.
      destruct i as [ [ i | ] | ]; [ idtac | simpl | simpl]. 
      + (* boundary of the corresponding original premise *)
        refine (Fmap_Raw_Syntax
          (associated_congruence_rule_original_constructor_translation _ _) _).
        apply (RS_hyp_bdry_instance_of_premise R p_orig).
      + (* LHS of new equality premise *)
        cbn. simple refine (symb_raw' _ _ _).
        * apply inr_Metavariable.
          refine (inl p; _).
          apply inr, idpath.
        * apply idpath.
        * intros i.
          apply var_raw, (coproduct_inj1 shape_is_coproduct), i.
      + (* RHS of new equality premise *)
        cbn. simple refine (symb_raw' _ _ _).
        * apply inr_Metavariable.
          refine (inr p; _).
          apply inr, idpath.
        * apply idpath.
        * intros i.
          apply var_raw, (coproduct_inj1 shape_is_coproduct), i.
    - (* RS_context_expr_of_conclusion *)
      intros i.
      refine (Fmap_Raw_Syntax _ (RS_context_expr_of_conclusion R i)).
      apply Fmap2_Metavariable_Extension, inl_Family.
    - (* RS_hyp_judgt_bdry_instance_of_conclusion *)
      intros [ [ i | ] | ]; simpl. 
      + (* boundary of original conclusion *)
        refine (Fmap_Raw_Syntax _ _).
        * apply Fmap2_Metavariable_Extension, inl_Family.
        * destruct hjf_concl as [cl | ?].
          -- exact (RS_hyp_judgt_bdry_instance_of_conclusion R i).
          -- destruct H. (* [hjf_concl] can’t be an equality judgement *)
      + (* LHS of new conclusion *)
        cbn. simple refine (symb_raw' _ _ _).
        * apply inl_Symbol, S.
        * apply e_cl.
        * change (arity (inl_Symbol S)) with (arity S).
          destruct (e_a^); clear e_a.
          intros [ p | i ].
          -- simple refine (symb_raw' _ _ _).
             ++ apply inr_Metavariable.
                exact (inl p).
             ++ apply idpath.
             ++ cbn. intros i.
                apply var_raw. 
                apply (coproduct_inj1 shape_is_coproduct).
                apply (coproduct_inj2 shape_is_coproduct).
                exact i.
          -- apply var_raw, (coproduct_inj1 shape_is_coproduct), i.
      + (* RHS of new conclusion *)
        cbn. simple refine (symb_raw' _ _ _).
        * apply inl_Symbol, S.
        * apply e_cl.
        * change (arity (inl_Symbol S)) with (arity S).
          destruct (e_a^); clear e_a.
          intros [ p | i ].
          -- simple refine (symb_raw' _ _ _).
             ++ apply inr_Metavariable.
                exact (inr p).
             ++ apply idpath.
             ++ cbn. intros i.
                apply var_raw. 
                apply (coproduct_inj1 shape_is_coproduct).
                apply (coproduct_inj2 shape_is_coproduct).
                exact i.
          -- apply var_raw, (coproduct_inj1 shape_is_coproduct), i.
  Defined.
  (* TODO: the above is a bit unreadable.  An alternative approach that might be clearer and more robust:
   - factor out the constructions of the head terms of conclusions and premises from [Raw_Rule_of_Rule_Spec], if doable.
   - here, invoke those, but (for the LHS/RHS of the new equalities), translate them under appropriate context morphisms “inl”, “inr”. *)

(* A good test proposition will be the following: whenever a rule-spec is well-typed, then so is its associated congruence rule-spec. *)

End Raw_Rules_of_Rule_Specs.
