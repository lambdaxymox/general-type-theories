Require Import HoTT.
Require Import Auxiliary.Coproduct.
Require Import Auxiliary.Family.
Require Import Auxiliary.Closure.
Require Import Syntax.ShapeSystem.
Require Import Syntax.All.
Require Import Typing.Context.
Require Import Typing.Judgement.


Section FlatRule.

  Context {σ : shape_system}.
  Context {Σ : signature σ}.

  (* TODO: Is it right that we allow arbitrary judgements, or should we allow
     only _hypothetical_ judgements? *)
  Record flat_rule
  :=
    { flat_rule_metas : arity _
    ; flat_rule_premise :
        family (judgement_total (Metavariable.extend Σ flat_rule_metas))
    ; flat_rule_conclusion :
        (judgement_total (Metavariable.extend Σ flat_rule_metas))
    }.

  Local Lemma eq
      {R R' : flat_rule}
      (e_metas : flat_rule_metas R = flat_rule_metas R')
      (e_premises
       : transport (fun a => family (_ (_ _ a))) e_metas
                   (flat_rule_premise R)
         = flat_rule_premise R')
      (e_conclusion
       : transport (fun a => judgement_total (_ _ a)) e_metas
                   (flat_rule_conclusion R)
         = flat_rule_conclusion R')
    : R = R'.
  Proof.
    destruct R, R'; cbn in *.
    destruct e_metas, e_premises, e_conclusion.
    apply idpath.
  Defined.

  Local Definition closure_system (R : flat_rule)
    : Closure.system (judgement_total Σ).
  Proof.
    exists { Γ : raw_context Σ &
                 Metavariable.instantiation (flat_rule_metas R) Σ Γ }.
    intros [Γ I].
    split.
    - (* premises *)
      refine (Family.fmap _ (flat_rule_premise R)).
      apply (Judgement.instantiate _ I).
    - apply (Judgement.instantiate _ I).
      apply (flat_rule_conclusion R).
  Defined.

End FlatRule.

Arguments flat_rule {_} _.
Arguments closure_system {_ _} _.

Section SignatureMaps.

  Context `{Funext} {σ : shape_system}.

  Local Definition fmap
        {Σ Σ' : signature σ} (f : Signature.map Σ Σ')
    : flat_rule Σ -> flat_rule Σ'.
  Proof.
    intros R.
    exists (flat_rule_metas R).
    - refine (Family.fmap _ (flat_rule_premise R)).
      apply fmap_judgement_total.
      apply Metavariable.fmap1, f.
    - refine (fmap_judgement_total _ (flat_rule_conclusion R)).
      apply Metavariable.fmap1, f.
  Defined.

  Local Definition fmap_closure_system 
        {Σ Σ' : signature σ} (f : Signature.map Σ Σ')
        (R : flat_rule Σ)
    : Family.map_over (Closure.fmap (fmap_judgement_total f))
        (closure_system R)
        (closure_system (fmap f R)).
  Proof.
    apply Family.Build_map'.
    intros [Γ I_R].
    exists (Context.fmap f Γ ; fmap_instantiation f I_R).
    apply Closure.rule_eq.
    - simple refine (Family.eq _ _). { apply idpath. }
      cbn. intros i. apply inverse, Judgement.fmap_instantiate.
    - cbn. apply inverse, Judgement.fmap_instantiate.
  Defined.

  Local Lemma fmap_idmap
      {Σ : signature σ} (R : flat_rule Σ)
    : fmap (Signature.idmap _) R = R.
  Proof.
    simple refine (eq _ _ _).
    - apply idpath.
    - cbn.
      eapply concat.
      { refine (ap (fun f => Family.fmap f _) _).
        eapply concat. { apply ap, Metavariable.fmap1_idmap. }
        apply path_forall; intros i.
        apply Judgement.fmap_judgement_total_idmap. }
      apply Family.fmap_idmap.
    - cbn.
      eapply concat. 2: { apply fmap_judgement_total_idmap. }
      apply ap10, ap. apply Metavariable.fmap1_idmap.
  Defined.

  Local Lemma fmap_compose
      {Σ Σ' Σ'' : signature σ}
      (f : Signature.map Σ Σ') (f' : Signature.map Σ' Σ'')
      (R : flat_rule Σ)
    : fmap (Signature.compose f' f) R
      = fmap f' (fmap f R).
  Proof.
    simple refine (eq _ _ _).
    - apply idpath.
    - cbn.
      eapply concat. 2: { apply Family.fmap_compose. }
      refine (ap (fun f => Family.fmap f _) _).
      eapply concat. { apply ap, Metavariable.fmap1_compose. }
      apply path_forall; intros i.
      apply fmap_judgement_total_compose.
    - cbn.
      eapply concat. 2: { apply fmap_judgement_total_compose. }
      apply ap10, ap, Metavariable.fmap1_compose.
  Defined.

End SignatureMaps.


(** Instantiations?  The interaction between flat rules and instantiations — in particular, the interaction with [FlatRule.closure_system] — can’t be given here, since it depends on structural rules, at least on the rule for variable-renaming.  So see [Typing.FlatTypeTheory] downstream for lemmas on this, and the comments at  [instantiate_flat_rule_closure_system] there for a more detailed explanation. *)

(* NOTE: what we could give here, and should if it’s needed anywhere, would be the “functoriality of flat rules under instantiations”: i.e. translating a flat rule over [Σ+a] to a flat rule over [Σ], using [Judgement.instantiate]. *)