DROP VIEW IF EXISTS gn_monitoring.v_synthese_flore_patrimoniale;
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_flore_patrimoniale AS
WITH t_source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('FLORE_PATRIMONIALE'::text))
        ), observers AS (
         SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers,
            cvo.id_base_visit
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY cvo.id_base_visit
        )
 SELECT to2.uuid_observation AS unique_id_sinp,
    tbs.uuid_base_site AS unique_id_sinp_grp,
    t_source.id_source,
    to2.id_observation AS entity_source_pk_value,
    tbv.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying) AS id_nomenclature_obs_meth,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    NULLIF((toc.data::json #> '{nombre}'::text[])::text, 'null'::text)::integer AS count_min,
    NULLIF((toc.data::json #> '{nombre}'::text[])::text, 'null'::text)::integer AS count_max,
    to2.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    tbs.geom AS the_geom_4326,
    st_centroid(tbs.geom) AS the_geom_point,
    tbs.geom_local AS the_geom_local,
    tbv.visit_date_min AS date_min,
    COALESCE(tbv.visit_date_max, tbv.visit_date_min) AS date_max,
    tbv.id_base_visit AS id_visit,
    tbv.visit_date_max,
    tbv.id_digitiser,
    tbs.id_inventor,
    concat(tr.nom_role, ' ', tr.prenom_role) AS observers,
    tm.id_module,
    tbv.comments AS comment_context,
    to2.comments AS comment_description,
    obs.ids_observers,
    tbv.id_base_site,
    tbv.id_base_visit
   FROM gn_monitoring.t_base_sites tbs
     LEFT JOIN gn_monitoring.t_site_complements tsc ON tsc.id_base_site = tbs.id_base_site
     LEFT JOIN gn_monitoring.t_base_visits tbv ON tbs.id_base_site = tbv.id_base_site
     LEFT JOIN observers obs ON obs.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = tbv.id_base_visit
     LEFT JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     LEFT JOIN utilisateurs.t_roles tr ON tr.id_role = tbv.id_digitiser
     LEFT JOIN taxonomie.taxref t ON to2.cd_nom = t.cd_nom
     LEFT JOIN t_source ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(tbs.geom_local) alt(altitude_min, altitude_max) ON true
     LEFT JOIN gn_commons.t_modules tm ON tbv.id_module = tm.id_module
  WHERE tm.module_label::text ilike 'FLORE%PATRIMONIALE'::text
  AND to2.cd_nom IS NOT NULL
  AND to2.uuid_observation IS NOT NULL;
