-- Enable REST access for demo schema via ORDS
-- Requires: DEMO_SCHEMA as substitution variable
-- Note: Must run AFTER ORDS is registered (ORDS_ADMIN must exist)

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled => TRUE,
    p_schema  => '&DEMO_SCHEMA',
    p_url_mapping_type => 'BASE_PATH',
    p_url_mapping_pattern => LOWER('&DEMO_SCHEMA'),
    p_auto_rest_auth => TRUE
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ REST enabled for schema: &DEMO_SCHEMA');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('⚠️  Error enabling REST: ' || SQLERRM);
    RAISE;
END;
/
