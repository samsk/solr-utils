/** ArrayTransformer.java */
package sk.dob.search.solr.dih;

import java.sql.*;
import java.util.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.apache.solr.handler.dataimport.*;

public class SQLArrayTransformer extends Transformer {
	private static final Logger LOG = LoggerFactory.getLogger(SQLArrayTransformer.class);

	public Map<String, Object> transformRow(Map<String, Object> row, Context context) {
		List<Map<String, String>> fields = context.getAllEntityFields();

		for (Map<String, String> field : fields) {
			List<String> list = new ArrayList<String>();
				
			String column = field.get(DataImporter.COLUMN);
			Object value = row.get(column);

			if (value != null) {
				try {
					ResultSet rs = ((java.sql.Array)value).getResultSet();
					while (rs.next()) {
						// PostgreSQL arrays work this way
						list.add(rs.getString(2));
					}
				} catch (SQLException e) {
					LOG.error("SQLArray splitting failed for column " + column + ":", e);

					list.clear();
					list.add(value.toString());
				}
			}
			row.put(column, list);
		}
		return row;
	}
}
