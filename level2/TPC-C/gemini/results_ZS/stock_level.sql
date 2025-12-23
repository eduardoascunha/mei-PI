CREATE OR REPLACE FUNCTION stock_level (
    w_id_in INTEGER,
    d_id_in INTEGER,
    threshold_in INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_next_o_id INTEGER;
    v_low_stock INTEGER;
BEGIN
    -- Get the next available order ID for the district
    SELECT d.d_next_o_id
    INTO v_next_o_id
    FROM bmsql_district AS d
    WHERE d.d_w_id = w_id_in AND d.d_id = d_id_in;

    -- Count the number of distinct items from the last 20 orders
    -- that have a stock quantity below the threshold.
    SELECT count(*)
    INTO v_low_stock
    FROM bmsql_stock s
    WHERE s.s_w_id = w_id_in
      AND s.s_quantity < threshold_in
      AND s.s_i_id IN (
          SELECT DISTINCT ol.ol_i_id
          FROM bmsql_order_line ol
          WHERE ol.ol_w_id = w_id_in
            AND ol.ol_d_id = d_id_in
            AND ol.ol_o_id < v_next_o_id
            AND ol.ol_o_id >= v_next_o_id - 20
      );

    RETURN v_low_stock;
END;
$$ LANGUAGE plpgsql;