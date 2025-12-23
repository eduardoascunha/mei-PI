CREATE OR REPLACE FUNCTION bmsql_proc_stock_level(
  w_id_in integer,
  d_id_in integer,
  threshold integer
) RETURNS integer AS $$
DECLARE
  v_d_next_o_id integer;
  v_low_stock integer;
BEGIN
  SELECT d.d_next_o_id
  INTO v_d_next_o_id
  FROM bmsql_district AS d
  WHERE d.d_w_id = w_id_in AND d.d_id = d_id_in;

  SELECT count(*)
  INTO v_low_stock
  FROM bmsql_stock s
  WHERE s.s_w_id = w_id_in
    AND s.s_quantity < threshold
    AND s.s_i_id IN (
      SELECT DISTINCT ol.ol_i_id
      FROM bmsql_order_line ol
      WHERE ol.ol_w_id = w_id_in
        AND ol.ol_d_id = d_id_in
        AND ol.ol_o_id < v_d_next_o_id
        AND ol.ol_o_id >= (v_d_next_o_id - 20)
    );

  RETURN v_low_stock;
END;
$$ LANGUAGE plpgsql;