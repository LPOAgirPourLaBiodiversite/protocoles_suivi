------------------------------------------------- export loutre local ------------------------------------------
-- View: gn_monitoring.v_export_suiviblaireau_telecharger_csv


DROP VIEW  IF EXISTS  gn_monitoring.v_export_synthese_suivi;

CREATE OR REPLACE VIEW gn_monitoring.v_export_synthese_suiv 
 AS
SELECT
id_synthese
FROM gn_synthese.synthese 
limit 1



