/*dans le cas de l'exemple, les données sont collectées à l'échelle départementales mais tout autre échelle est possible.
  Les zonages concernées sont actifs dans le l_areas.
  On génère à la volée les sites et les visites pour limiter le travail de saisie.
 */

-- insertion des sites
begin;
update ref_geo.l_areas
set enable= false
where id_type = ref_geo.get_id_area_type('DEP')
  and enable is true
  and area_code not in ('01', '07', '03', '26', '38', '42', '69', '73', '74', '15', '63', '43');
commit;
begin;
set session_replication_role = 'replica';
with dep as (select * from ref_geo.l_areas where id_type = ref_geo.get_id_area_type('DEP') and enable)
insert
into gn_monitoring.t_base_sites (base_site_name, geom, geom_local)
select area_name, st_transform(geom, 4326), geom
from dep;
set session_replication_role = 'origin';
rollback;
commit;
/*	insert into gn_monitoring.cor_site_module (id_base_site, id_module)
	select id_base_site,gn_commons.get_id_module_bycode('synthese_suivi') from gn_monitoring.t_base_sites
	where meta_create_date::date=now()::date;*/
insert into gn_monitoring.cor_site_type(id_type_site, id_base_site)
SELECT (select id_nomenclature from ref_nomenclatures.t_nomenclatures where cd_nomenclature = 'SYNT_SUIVI'),
	   id_base_site
from gn_monitoring.t_base_sites
where meta_create_date::date = now()::date;

insert into gn_monitoring.t_site_complements (id_base_site, data)
select id_base_site, '{}'
from gn_monitoring.t_base_sites
where meta_create_date::date = now()::date;

select *
from gn_monitoring.t_site_complements;

-- génération des visites à la volée
/*attention aux bones voulues*/

with serie_temp as (SELECT generate_series(2000, EXTRACT(YEAR FROM now())::int) AS an),
	 periode as (select 'repro' as periode union select 'hiver')
		,
	 prep_visite as (select distinct cor.id_base_site, periode, an
					 from gn_monitoring.t_base_sites
							  join gn_monitoring.cor_site_type cor on t_base_sites.id_base_site = cor.id_base_site
						, periode
						, serie_temp
					 where cor.id_type_site = (select id_nomenclature
											   from ref_nomenclatures.t_nomenclatures
											   where cd_nomenclature = 'SYNT_SUIVI'))
insert
into gn_monitoring.t_base_visits (id_base_site, id_dataset, id_module, comments, visit_date_min)
select id_base_site,
	   1,
	   gn_commons.get_id_module_bycode('synthese_suivi'),
	   json_build_object('periode', periode, 'an', an, 'insert_date', now()
	   ),
	   now()
from prep_visite;

select *
from gn_monitoring.t_visit_complements;


insert into gn_monitoring.t_visit_complements (id_base_visit, data)
select id_base_visit, comments::jsonb - 'insert_date'
from gn_monitoring.t_base_visits
where comments::jsonb ->> 'periode' is not null
  and comments::jsonb ->> 'an' is not null
  and comments::jsonb ->> 'insert_date' is not null
;


--création de la liste espèce

insert into taxonomie.bib_listes (code_liste, nom_liste, desc_liste)
select '200', 'Synthèse suivi', 'Liste de taxons utilisée pour le module ''Synthèse de suivi'
;
-- insertion des cd_nom
begin;
with cd_nom as (select 2440 as cd_nom --grand cormoran
				UNION
				select 2504 -- grande aigrette
				UNION
				select 2506 --héron cendré
				UNION
				select 2508 --héron pourpré
				UNION
				select 2486 --crabier
				UNION
				select 2473 --butor
				UNION
				select 2489 -- gardeboeuf
				UNION
				select 2497 --aigrette garzette
				UNION
				select 2477 -- blongios
				UNION
				select 2481 --bihoreau
				UNION
				select 530157 --mouette rieuse
				UNION
				select 199374 --goéland leucophée
				UNION
				select 3293 --goéland cendré
				UNION
				select 3297 --goéland brun
				UNION
				select 459627 --Guifette moustac
				UNION
				select 3371 --Guifette noire
				UNION
				select 3343 --Sterne pierregarin
				UNION
				select 3352 --Sterne naine
				UNION
				select 2895--Épervier d'Europe
				UNION
				select 2645--Aigle royal
				UNION
				select 2657--Aigle de Bonelli
				UNION
				select 2623--Buse variable
				UNION
				select 2873--Circaète Jean-le-Blanc
				UNION
				select 2878--Busard des roseaux
				UNION
				select 2881--Busard Saint-Martin
				UNION
				select 2887--Busard cendré
				UNION
				select 2836--Élanion blanc
				UNION
				select 2852--Gypaète barbu
				UNION
				select 2860--Vautour fauve
				UNION
				select 2848--Pygargue à queue blanche
				UNION
				select 2651--Aigle botté
				UNION
				select 2840--Milan noir
				UNION
				select 2844--Milan royal
				UNION
				select 2856--Vautour percnoptère
				UNION
				select 2832--Bondrée apivore
				UNION
				select 3701 --Hirondelle rousseline
				UNION
				select 459478 --Hirondelle de fenêtre
				UNION
				select 3688 --Hirondelle de rivage
				UNION
				select 3696 --"Hirondelle rustiqueUNION select Hirondelle de cheminée"
				UNION
				select 3551 --Martinet noir
				UNION
				select 3555 --Martinet pâle
				UNION
				select 3561 --"Martinet à ventre blanc"
				UNION
				select 2543 --"Bécassine des marais"
				UNION
				select 2538 --Bécassine sourde
				UNION
				select 3053 --Râle des genêts
				UNION
				select 3067 --"Talève sultaneUNION select Poule sultaneUNION select Porphyrion bleu"
				UNION
				select 3039 --Marouette ponctuée
				UNION
				select 836245 --Marouette poussin
				UNION
				select 2517 --Ciconia ciconia
				UNION
				select 2514 --Ciconia nigra
				UNION
				select 3089 --outarde
				UNION
				select 2576 --courlis cendré
				UNION
				select 3120 --oedicnème
				UNION
				select 192950 --grue cendré
				UNION
				select 459629 --lagopède
				UNION
				select 2962 --tétras lyre
				UNION
				select 3533--"Chouette de Tengmalm, Nyctale de Tengmalm"
				UNION
				select 3522--Hibou moyen-duc
				UNION
				select 3507--"Chevêchette d'Europe, Chouette chevêchette"
				UNION
				select 728079--"Effraie des clochers, Chouette effraie"
				UNION
				select 3525--Hibou des marais
				UNION
				select 3482--"Effraie des clochers, Chouette effraie"
				UNION
				select 3489--"Petit-duc scops, Hibou petit-duc"
				UNION
				select 3493--Grand-duc d'Europe'
				UNION
				select 3511--"Chevêche d''Athéna, Chouette chevêche"
)
insert
into taxonomie.cor_nom_liste (id_liste, cd_nom)
select (select id_liste from taxonomie.bib_listes where nom_liste = 'Synthèse suivi'), cd_nom
from cd_nom
on conflict do nothing;
ROLLBACK ;
--COMMIT;
