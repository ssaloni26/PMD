/**
 * The DynamicCSVParser class is a lightweight CSV parsing utility that converts CSV text into a list of maps,
 * where each map represents a row with column headers as keys.
 * 
 * Enhancements:
 *  - Handles CSVs with Windows/Mac/Linux line endings.
 *  - Handles quoted fields and escaped double quotes.
 *  - Limits parsing to a maximum of 1000 data rows (excluding the header).
 */
public class DynamicCSVParser {
    
    private static final Integer MAX_ROW_LIMIT = 1500; // configurable row limit

    public static List<Map<String, String>> parseCSV(String csvString) {
        List<Map<String, String>> parsedData = new List<Map<String, String>>();
        if (String.isBlank(csvString)) return parsedData;

        // Normalize line endings
        csvString = csvString.replace('\r\n', '\n').replace('\r', '\n');
        List<String> lines = splitLines(csvString);
        if (lines.isEmpty()) return parsedData;

        // Read headers
        List<String> headers = parseCSVLine(lines[0]);
        Integer totalLines = lines.size();

        // Limit data rows to MAX_ROW_LIMIT
        Integer limit1 = Math.min(totalLines - 1, MAX_ROW_LIMIT);

        // Parse each line up to the limit1
        for (Integer i = 1; i <= limit1; i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;

            List<String> values = parseCSVLine(line);
            Map<String, String> row = new Map<String, String>();

            for (Integer j = 0; j < headers.size(); j++) {
                String key = headers[j];
                String value = j < values.size() ? values[j] : '';
                row.put(key, value);
            }

            parsedData.add(row);
        }

        // Optionally: log if truncated
        if (totalLines - 1 > MAX_ROW_LIMIT) {
            System.debug('⚠️ CSV truncated to first ' + MAX_ROW_LIMIT + ' rows (out of ' + (totalLines - 1) + ').');
        }

        return parsedData;
    }

    private static List<String> splitLines(String csv) {
        List<String> lines = new List<String>();
        Integer start = 0;

        while (start < csv.length()) {
            Integer lineBreak = csv.indexOf('\n', start);
            if (lineBreak == -1) {
                lines.add(csv.substring(start));
                break;
            }
            lines.add(csv.substring(start, lineBreak));
            start = lineBreak + 1;
        }

        return lines;
    }

    private static List<String> parseCSVLine(String line) {
        List<String> result = new List<String>();
        Boolean inQuotes = false;
        String current = '';
        Integer i = 0;

        while (i < line.length()) {
            String ch = line.substring(i, i + 1);

            if (ch == '"') {
                if (inQuotes && i + 1 < line.length() && line.substring(i + 1, i + 2) == '"') {
                    current += '"';
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (ch == ',' && !inQuotes) {
                result.add(current);
                current = '';
            } else {
                current += ch;
            }
            i++;
        }

        result.add(current);
        return result;
    }
}