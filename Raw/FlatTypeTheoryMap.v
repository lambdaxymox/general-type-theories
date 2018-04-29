Require Import HoTT.
Require Import Auxiliary.Family.
Require Import Proto.ShapeSystem.
Require Import Auxiliary.Coproduct.
Require Import Auxiliary.Closure.
Require Import Raw.Syntax.
Require Import Raw.RawSubstitution.
Require Import Raw.FlatRule.
Require Import Raw.RawStructuralRule.
Require Import Raw.FlatTypeTheory.
Require Import Raw.RawTypeTheory.

Section FlatTypeTheoryMap.

  Context `{H : Funext}.
  Context {σ : shape_system}.

  (* TODO:
    possibly the [Signature.map] should be extracted as a parameter,
    à la displayed categories?
  *)
  Record flat_type_theory_map
    {Σ : signature σ} (T : flat_type_theory Σ)
    {Σ' : signature σ} (T' : flat_type_theory Σ')
  := { fttm_signature_map :> Signature.map Σ Σ'
     ; fttm_rule_derivation
       : forall R : T, FlatTypeTheory.flat_rule_derivation T'
                         (FlatRule.fmap fttm_signature_map (T R))
     }.

  (* TODO: upstream to [Auxiliary.Closure] *)
  Lemma one_step_derivation {X} {T : Closure.system X} (r : T)
    : Closure.derivation T
              (Closure.premises (T r)) (Closure.conclusion (T r)).
  Proof.
    refine (deduce T _ r _).
    intros i. exact (hypothesis T _ i).
  Defined.

  Definition fmap_closure_system
    {Σ : signature σ} (T : flat_type_theory Σ)
    {Σ' : signature σ} (T' : flat_type_theory Σ')
    (f : flat_type_theory_map T T')
  : Closure.map
      (Family.fmap (Closure.fmap (fmap_judgement_total f)) (FlatTypeTheory.closure_system T))
      (FlatTypeTheory.closure_system T').
  Proof.
    intros r. (* We need to unfold [r] a bit here, bit not too much. *)
    unfold Family.fmap, family_index, FlatTypeTheory.closure_system in r.
    destruct r as [ r_str | r_from_rr ].
    - (* Structural rules *)
      (* an instance of a structural rule is translated to an instance of the same structural rule *)
      set (f_r := RawStructuralRule.fmap f r_str).
      set (e_f_r := Family.map_commutes (RawStructuralRule.fmap f) r_str).
      set (e_prems := ap (@Closure.premises _) e_f_r).
      set (e_concl := ap (@Closure.conclusion _) e_f_r).
      refine (transport _ e_concl _).
      refine (transport (fun H => derivation _ H _) e_prems _).
      refine (map_derivation _ (one_step_derivation f_r)).
      apply Closure.map_from_family_map.
      apply Family.inl.
     - (* Logical rules *)
       cbn in r_from_rr. rename r_from_rr into r.
       destruct r as [i [Γ A]].
       cbn.
       set (fc := fttm_rule_derivation _ _ f i). (* TODO: implicits! *)
       set (c := T i) in *.
       set (a := flat_rule_metas Σ c) in *.
       unfold FlatTypeTheory.flat_rule_derivation in fc. cbn in fc.
       transparent assert (f_a : (Signature.map
             (Metavariable.extend Σ a) (Metavariable.extend Σ' a))).
       { apply Metavariable.fmap1, f. }
      (*
      Very concretely: fc is over Σ+a.  Must map to Σ'+a, then instantiate.

      *)
      (* OK, this can be all abstracted a bit better:
       - “derivable cc’s” gives a “monad” on closure systems; so “deduce-bind” or something, like “deduce” but with a derivable cc instead of an atomic one
       - any instantiation of a derivable flat rule gives a derivable closure condition over CCs_of_TT.
       - fmap on derivable closure conditions
       - fmap on ?? *)
  Admitted.

  (* TODO: maps of type theories preserve derivability. *)
End FlatTypeTheoryMap.
