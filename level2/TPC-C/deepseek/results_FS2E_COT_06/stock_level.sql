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
    SELECT INTO var_next_o_id
            d_next_o_id
        FROM bmsql_district
        WHERE d_w_id = in_w_id AND d_id = in_d_id;

    SELECT INTO out_low_stock
            COUNT(DISTINCT s_i_id)
        FROM bmsql_stock
        WHERE s_w_id = in_w_id
          AND s_quantity < in_threshold
          AND s_i_id IN (
            SELECT DISTINCT ol_i_id
                FROM bmsql_order_line
                WHERE ol_w_id = in_w_id
                  AND ol_d_id = in_d_id
                  AND ol_o_id >= var_next_o_id - 20
                  AND ol_o_id < var_next_o_id
            );
END;
$$
LANGUAGE plpgsql;