CREATE OR REPLACE FUNCTION bmsql_proc_stock_level(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_threshold integer,
    OUT out_low_stock integer
) AS
$$
DECLARE
    var_next_o_id integer;
BEGIN
    SELECT d_next_o_id INTO var_next_o_id
    FROM bmsql_district
    WHERE d_w_id = in_w_id AND d_id = in_d_id;

    SELECT COUNT(DISTINCT s.s_i_id) INTO out_low_stock
    FROM bmsql_order_line ol
    JOIN bmsql_stock s ON ol.ol_i_id = s.s_i_id AND s.s_w_id = in_w_id
    WHERE ol.ol_w_id = in_w_id 
      AND ol.ol_d_id = in_d_id 
      AND ol.ol_o_id >= var_next_o_id - 20 
      AND ol.ol_o_id < var_next_o_id
      AND s.s_quantity < in_threshold;
END;
$$
LANGUAGE plpgsql;