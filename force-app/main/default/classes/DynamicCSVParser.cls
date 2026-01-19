/**
 * The DynamicCSVParser class is a lightweight CSV parsing utility that converts CSV text into a list of maps,
 * where each map represents a row with column headers as keys.
 * 
 */
public class DynamicCSVParser {
    public static List<Map<String, String>> parseCSV(String csvString) {
        List<Map<String, String>> parsedData = new List<Map<String, String>>();
        csvString = csvString.replace('\r\n', '\n').replace('\r', '\n');
        List<String> lines = splitLines(csvString,50000);
        if (lines.isEmpty()) return parsedData;
        List<String> headers = lines[0].replace('"','').split(',');
        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i];
            if (String.isBlank(line)) continue;

            List<String> values = line.split(',');
            Map<String, String> row = new Map<String, String>();

            for (Integer j = 0; j < headers.size(); j++) {
                String value = j < values.size() ? values[j] : '';
                row.put(headers[j], value.replace('"',''));
            }
            
            parsedData.add(row);
        }
        return parsedData;
    }

	public static List<String> splitLines(String csvStr,Integer chunkSize){
        List<String> chunks = new List<String>();
        Integer startIndex = 0;
        Integer length = csvStr.length();
    
        while (startIndex < length) {
            Integer searchFrom = Math.min(startIndex + chunkSize, length - 1);
            Integer endIndex = csvStr.indexOf('\n', searchFrom);
    
            if (endIndex == -1) {
                endIndex = length;
            } else {
                endIndex++; 
            }
    
            String subStr = csvStr.substring(startIndex, endIndex);
            chunks.addAll(subStr.split('\n'));

            startIndex = endIndex;
        }
		return chunks;
	}
}