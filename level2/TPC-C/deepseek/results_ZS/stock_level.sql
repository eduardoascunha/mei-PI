CREATE OR REPLACE FUNCTION stock_level_transaction(
    p_w_id integer,
    p_d_id integer,
    p_threshold integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_next_o_id integer;
    v_low_stock integer;
BEGIN
    -- Get the next available order number from district
    SELECT d.d_next_o_id INTO v_next_o_id
    FROM bmsql_district d
    WHERE d.d_w_id = p_w_id AND d.d_id = p_d_id;

    -- Count distinct items with stock below threshold from last 20 orders
    SELECT COUNT(DISTINCT s.s_i_id) INTO v_low_stock
    FROM bmsql_stock s
    WHERE s.s_w_id = p_w_id
      AND s.s_quantity < p_threshold
      AND s.s_i_id IN (
          SELECT DISTINCT ol.ol_i_id
          FROM bmsql_order_line ol
          WHERE ol.ol_w_id = p_w_id
            AND ol.ol_d_id = p_d_id
            AND ol.ol_o_id >= (v_next_o_id - 20)
            AND ol.ol_o_id < v_next_o_id
      );

    RETURN v_low_stock;
END;
$$;