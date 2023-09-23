defimpl Kino.Render, for: VegaLite do
  def to_livebook(vl) do
    json =
      vl
      |> VegaLite.Export.to_json()

    random_id = :crypto.strong_rand_bytes(8) |> Base.encode16()

    """
    <div id="graphic-#{random_id}"></div>
    <script type="text/javascript">
      var spec = JSON.parse("#{escape_double_quotes(json)}");
      vegaEmbed("#graphic-#{random_id}", spec);
    </script>
    """
  end

  defp escape_double_quotes(json) do
    String.replace(json, ~s{"}, ~s{\\"})
  end
end

defimpl Kino.Render, for: Kino.JS.Live do
  def to_livebook(%{module: Kino.Table} = live_js_kino_table) do
    state = :sys.get_state(live_js_kino_table.pid).ctx.assigns.state

    render_html_table(state[:columns], state[:data_rows])
  end

  defp render_html_table(columns, rows) do
    column_head_cells =
      columns
      |> Enum.map(fn column ->
        "<th>#{column.label}</th>"
      end)

    row_cells =
      rows
      |> Enum.reduce(["<tr>"], fn row, rows_acc ->
        columns
        |> Enum.reduce([], fn column, cols_acc ->
          cols_acc ++ ["<td>#{Map.get(row, column.key, "")}</td>"]
        end)
        |> then(fn tds -> rows_acc ++ [tds] end)
      end)
      |> Enum.intersperse("</tr><tr>")
      |> Kernel.++(["</tr>"])

    iodata =
      ["<table>", "<thead>"] ++
        column_head_cells ++
        ["</thead>", "<tbody>"] ++ row_cells ++ ["</tbody>", "</table>"]

    IO.iodata_to_binary(iodata)
  end
end
