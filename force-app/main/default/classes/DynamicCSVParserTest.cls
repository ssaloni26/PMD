@IsTest
private class DynamicCSVParserTest {

    @IsTest
    static void testEmptyCsv() {
        List<Map<String, String>> result = DynamicCSVParser.parseCSV('');
        System.assertEquals(0, result.size(), 'Empty CSV should return empty list');
    }

    @IsTest
    static void testNullCsv() {
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(null);
        System.assertEquals(0, result.size(), 'Null CSV should return empty list');
    }

    @IsTest
    static void testSimpleCsv() {
        String csv = 'Name,Age,Email\nJohn,25,john@example.com\nJane,30,jane@example.com';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        System.assertEquals(2, result.size(), 'CSV has 2 rows');

        Map<String, String> row1 = result[0];
        System.assertEquals('John', row1.get('Name'));
        System.assertEquals('25', row1.get('Age'));
        System.assertEquals('john@example.com', row1.get('Email'));

        Map<String, String> row2 = result[1];
        System.assertEquals('Jane', row2.get('Name'));
        System.assertEquals('30', row2.get('Age'));
        System.assertEquals('jane@example.com', row2.get('Email'));
    }

    @IsTest
    static void testCsvWithMissingValues() {
        String csv = 'Name,Age,Email\nJohn,25,\nJane,,jane@example.com';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        System.assertEquals('', result[0].get('Email'), 'Missing value should be empty string');
        System.assertEquals('', result[1].get('Age'), 'Missing value should be empty string');
    }

    @IsTest
    static void testCsvWithQuotesAndCommas() {
        String csv = 'Name,Address\n"John Doe","123 Main St, Apt 4"\n"Jane Smith","456 Oak St"';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        System.assertEquals('123 Main St, Apt 4', result[0].get('Address'));
        System.assertEquals('456 Oak St', result[1].get('Address'));
    }

    @IsTest
    static void testCsvWithEscapedQuotes() {
        String csv = 'Name,Quote\nJohn,"He said ""Hello"""';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        System.assertEquals('He said "Hello"', result[0].get('Quote'), 'Escaped quotes should be handled correctly');
    }

    @IsTest
    static void testCsvWithEmptyLines() {
        String csv = 'Name,Age\nJohn,25\n\nJane,30\n';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        System.assertEquals(2, result.size(), 'Empty lines should be skipped');
        System.assertEquals('Jane', result[1].get('Name'));
    }
}