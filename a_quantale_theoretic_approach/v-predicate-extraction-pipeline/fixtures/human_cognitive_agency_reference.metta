(Concept human cognitive_agency
  (spec

    (sorts
      ((perspective   (stv 0.9 0.86))
       (human         (stv 0.9 0.86))
       (human_view    (stv 0.9 0.86))
       (body          (stv 0.9 0.86))
       (world         (stv 0.9 0.86))
       (situation     (stv 0.9 0.86))
       (experience    (stv 0.9 0.86))
       (meaning       (stv 0.9 0.86))
       (mental_state  (stv 0.9 0.86))
       (goal          (stv 0.9 0.86))
       (decision      (stv 0.9 0.86))
       (action        (stv 0.9 0.86))
       (utterance     (stv 0.9 0.86))
       (community     (stv 0.9 0.86))))

    (ops
      (((operation cognitive_agency
          (arrow perspective))
        (stv 0.6048 0.715))

       ((operation view_as_human
          (arrow human perspective human_view))
        (stv 0.6048 0.715))

       ((operation base_human
          (arrow human_view human))
        (stv 0.6048 0.715))

       ((operation perspective_of_human_view
          (arrow human_view perspective))
        (stv 0.6048 0.715))

       ((operation perceive_human
          (arrow human_view body situation experience))
        (stv 0.6048 0.715))

       ((operation interpret_human
          (arrow human_view experience meaning))
        (stv 0.6048 0.715))

       ((operation reflect_human
          (arrow human_view meaning meaning))
        (stv 0.6048 0.715))

       ((operation update_by_meaning_human
          (arrow human_view mental_state meaning mental_state))
        (stv 0.6048 0.715))

       ((operation learn_human
          (arrow human_view mental_state experience mental_state))
        (stv 0.6048 0.715))

       ((operation recall_human
          (partial_arrow human_view mental_state situation experience))
        (stv 0.6048 0.715))

       ((operation deliberate_human
          (arrow human_view mental_state goal decision))
        (stv 0.6048 0.715))

       ((operation choose_human
          (arrow human_view decision action))
        (stv 0.6048 0.715))

       ((operation perform_human
          (arrow human_view action world world))
        (stv 0.6048 0.715))

       ((operation express_human
          (arrow human_view meaning utterance))
        (stv 0.6048 0.715))

       ((operation neutral_meaning
          (arrow meaning))
        (stv 0.6048 0.715))

       ((operation compose_meaning
          (arrow meaning meaning meaning))
        (stv 0.6048 0.715))

       ((operation no_action
          (arrow action))
        (stv 0.6048 0.715))

       ((operation compose_action
          (arrow action action action))
        (stv 0.6048 0.715))))

    (preds
      (((embodied_by human body)
        (stv 0.672 0.715))

       ((situated_in human world)
        (stv 0.672 0.715))

       ((has_mental_state human mental_state)
        (stv 0.672 0.715))

       ((pursues_goal human goal)
        (stv 0.672 0.715))

       ((performs_action human action)
        (stv 0.672 0.715))

       ((expresses_meaning human meaning)
        (stv 0.672 0.715))

       ((communicates_with human human)
        (stv 0.672 0.715))

       ((belongs_to human community)
        (stv 0.672 0.715))))

    (axioms

      (((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency view_as_human)
            (declaredOperation human cognitive_agency base_human))
          (forall ((h human))
            (= (base_human (view_as_human h cognitive_agency))
               h)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency view_as_human)
            (declaredOperation human cognitive_agency perspective_of_human_view))
          (forall ((h human))
            (= (perspective_of_human_view
                 (view_as_human h cognitive_agency))
               cognitive_agency)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency compose_meaning)
            (declaredOperation human cognitive_agency neutral_meaning))
          (forall ((m meaning))
            (= (compose_meaning neutral_meaning m)
               m)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency compose_meaning)
            (declaredOperation human cognitive_agency neutral_meaning))
          (forall ((m meaning))
            (= (compose_meaning m neutral_meaning)
               m)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency compose_meaning))
          (forall ((m1 meaning) (m2 meaning) (m3 meaning))
            (= (compose_meaning (compose_meaning m1 m2) m3)
               (compose_meaning m1 (compose_meaning m2 m3)))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency reflect_human))
          (forall ((v human_view) (m meaning))
            (= (reflect_human v (reflect_human v m))
               (reflect_human v m))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency reflect_human)
            (declaredOperation human cognitive_agency neutral_meaning))
          (forall ((v human_view))
            (= (reflect_human v neutral_meaning)
               neutral_meaning)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency perceive_human)
            (declaredOperation human cognitive_agency interpret_human)
            (declaredOperation human cognitive_agency reflect_human))
          (forall ((v human_view) (b body) (s situation))
            (= (interpret_human v (perceive_human v b s))
               (reflect_human
                 v
                 (interpret_human v (perceive_human v b s))))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency update_by_meaning_human)
            (declaredOperation human cognitive_agency neutral_meaning))
          (forall ((v human_view) (st mental_state))
            (= (update_by_meaning_human v st neutral_meaning)
               st)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency learn_human)
            (declaredOperation human cognitive_agency update_by_meaning_human)
            (declaredOperation human cognitive_agency interpret_human))
          (forall ((v human_view) (st mental_state) (e experience))
            (= (learn_human v st e)
               (update_by_meaning_human
                 v
                 st
                 (interpret_human v e)))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency recall_human)
            (declaredOperation human cognitive_agency learn_human)
            (declaredOperation human cognitive_agency update_by_meaning_human)
            (declaredOperation human cognitive_agency interpret_human))
          (forall ((v human_view) (st mental_state) (s situation))
            (=>
              (defined (recall_human v st s))
              (= (learn_human
                   v
                   st
                   (recall_human v st s))
                 (update_by_meaning_human
                   v
                   st
                   (interpret_human
                     v
                     (recall_human v st s)))))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency deliberate_human)
            (declaredOperation human cognitive_agency update_by_meaning_human)
            (declaredOperation human cognitive_agency reflect_human))
          (forall ((v human_view) (st mental_state) (m meaning) (g goal))
            (= (deliberate_human
                 v
                 (update_by_meaning_human v st m)
                 g)
               (deliberate_human
                 v
                 (update_by_meaning_human v st (reflect_human v m))
                 g))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency express_human)
            (declaredOperation human cognitive_agency reflect_human))
          (forall ((v human_view) (m meaning))
            (= (express_human v m)
               (express_human v (reflect_human v m)))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency perform_human)
            (declaredOperation human cognitive_agency no_action))
          (forall ((v human_view) (w world))
            (= (perform_human v no_action w)
               w)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency compose_action)
            (declaredOperation human cognitive_agency no_action))
          (forall ((a action))
            (= (compose_action no_action a)
               a)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency compose_action)
            (declaredOperation human cognitive_agency no_action))
          (forall ((a action))
            (= (compose_action a no_action)
               a)))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency compose_action))
          (forall ((a1 action) (a2 action) (a3 action))
            (= (compose_action (compose_action a1 a2) a3)
               (compose_action a1 (compose_action a2 a3)))))
        (stv 0.672 0.715))

       ((=>
          (and
            (inPerspective human cognitive_agency)
            (declaredOperation human cognitive_agency perform_human)
            (declaredOperation human cognitive_agency compose_action))
          (forall ((v human_view) (a1 action) (a2 action) (w world))
            (= (perform_human v (compose_action a1 a2) w)
               (perform_human v a2 (perform_human v a1 w)))))
        (stv 0.672 0.715))))))
