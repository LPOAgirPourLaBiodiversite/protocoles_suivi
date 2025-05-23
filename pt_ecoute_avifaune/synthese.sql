
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_pt_ecoute_avifaune
AS WITH source AS (
         SELECT t_sources.id_source
           FROM gn_synthese.t_sources
          WHERE t_sources.name_source::text = concat('MONITORING_', upper('pt_ecoute_avifaune'::text))
         LIMIT 1
        ), observers AS (
         SELECT
                CASE
                    WHEN cvo.id_role IS NULL THEN v_1.data ->> 'observers_txt'::text
                    ELSE string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text)
                END AS observers,
                CASE
                    WHEN cvo.id_role IS NOT NULL THEN array_agg(r.id_role)
                    ELSE NULL::integer[]
                END AS ids_observers,
            v_1.id_base_visit
           FROM gn_monitoring.t_visit_complements v_1
             LEFT JOIN gn_monitoring.cor_visit_observer cvo ON cvo.id_base_visit = v_1.id_base_visit
             LEFT JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          GROUP BY v_1.id_base_visit, cvo.id_role
        )
 SELECT to2.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    source.id_source,
    to2.id_observation AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO'::character varying, 'St'::character varying) AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_tech_collect_campanule,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR'::character varying, 'Co'::character varying) AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    ref_nomenclatures.get_id_nomenclature('NATURALITE'::character varying, '1'::character varying) AS id_nomenclature_naturalness,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'REL'::character varying) AS id_nomenclature_grp_typ,
        CASE
            WHEN ((toc.data ->> 'en_vol'::text)::boolean) = true THEN ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '0'::character varying)
            ELSE ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '1'::character varying)
        END AS id_nomenclature_obs_technique,
    t.cd_nom,
    t.nom_complet AS nom_cite,
    s.altitude_min,
    s.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    v.id_module,
    v.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit,
    to2.id_observation,
    COALESCE(
	  	NULLIF(
		  	COALESCE((toc.data ->> 'nb_0_5')::integer,0) + 
		  	COALESCE((toc.data ->> 'nb_5_10')::integer,0) + 
		  	COALESCE((toc.data ->> 'nb_10_15')::integer,0) + 
		  	COALESCE((toc.data ->> 'nb_dist_inf_100_m')::integer,0)
	  	, 0)
	  , COALESCE((toc.data ->> 'nb_dist_supp_100_m')::integer,0) 
	  )  AS count_min,
     COALESCE(
	  	NULLIF(
		  	COALESCE((toc.data ->> 'nb_0_5')::integer,0) + 
		  	COALESCE((toc.data ->> 'nb_5_10')::integer,0) + 
		  	COALESCE((toc.data ->> 'nb_10_15')::integer,0) + 
		  	COALESCE((toc.data ->> 'nb_dist_inf_100_m')::integer,0)
	  	, 0)
	  , COALESCE((toc.data ->> 'nb_dist_supp_100_m')::integer,0) 
	  ) AS count_max
   FROM gn_monitoring.t_base_visits v
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_visit_complements vc ON vc.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observations to2 ON to2.id_base_visit = vc.id_base_visit
     JOIN gn_monitoring.t_observation_complements toc ON toc.id_observation = to2.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = to2.cd_nom
     LEFT JOIN observers obs ON obs.id_base_visit = v.id_base_visit
     JOIN source ON true 
  WHERE m.module_code::text = 'pt_ecoute_avifaune'::text;
 