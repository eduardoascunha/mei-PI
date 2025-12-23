CREATE OR REPLACE FUNCTION bmsql_proc_stock_level(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_threshold integer,
    OUT out_low_stock integer
) AS
$$
DECLARE
    var_next_o_id integer;
    var_i_id integer;
BEGIN
    -- Get the next available order number for the district.
    SELECT INTO var_next_o_id
            d_next_o_id
        FROM bmsql_district
        WHERE d_w_id = in_w_id AND d_id = in_d_id;

    -- Count the number of items with stock level below the threshold.
    SELECT INTO out_low_stock
            count(DISTINCT s_i_id)
        FROM bmsql_stock
        WHERE s_w_id = in_w_id
          AND s_i_id IN (
            SELECT DISTINCT ol_i_id
                FROM bmsql_order_line
                WHERE ol_w_id = in_w_id AND ol_d_id = in_d_id
                  AND ol_o_id < var_next_o_id AND ol_o_id >= var_next_o_id - 20
            )
          AND s_quantity < in_threshold;
END;
$$
LANGUAGE plpgsql;