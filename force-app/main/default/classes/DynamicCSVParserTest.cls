@IsTest
private class DynamicCSVParserTest {

    @IsTest
    static void testEmptyCSV() {
        List<Map<String, String>> result = DynamicCSVParser.parseCSV('');
        Assert.areEqual(0, result.size(), 'Parsing empty CSV should return empty list');
    }

    @IsTest
    static void testCSVWithOnlyHeaders() {
        String csv = 'Name,Age,Email';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);
        Assert.areEqual(0, result.size(), 'CSV with only headers should return empty list of rows');
    }

    @IsTest
    static void testCSVWithOneRow() {
        String csv = 'Name,Age,Email\nJohn Doe,30,john@example.com';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        Assert.areEqual(1, result.size(), 'CSV should return 1 row');

        Map<String, String> row = result[0];
        Assert.areEqual('John Doe', row.get('Name'));
        Assert.areEqual('30', row.get('Age'));
        Assert.areEqual('john@example.com', row.get('Email'));
    }

    @IsTest
    static void testCSVWithMultipleRows() {
        String csv = 'Name,Age,Email\nJohn,25,john@example.com\nJane,28,jane@example.com';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        Assert.areEqual(2, result.size(), 'CSV should return 2 rows');

        Map<String, String> row1 = result[0];
        Assert.areEqual('John', row1.get('Name'));
        Assert.areEqual('25', row1.get('Age'));
        Assert.areEqual('john@example.com', row1.get('Email'));

        Map<String, String> row2 = result[1];
        Assert.areEqual('Jane', row2.get('Name'));
        Assert.areEqual('28', row2.get('Age'));
        Assert.areEqual('jane@example.com', row2.get('Email'));
    }

    @IsTest
    static void testCSVWithMissingValues() {
        String csv = 'Name,Age,Email\nJohn,25,\nJane,,jane@example.com';
        List<Map<String, String>> result = DynamicCSVParser.parseCSV(csv);

        Assert.areEqual(2, result.size(), 'CSV should return 2 rows');

        Map<String, String> row1 = result[0];
        Assert.areEqual('John', row1.get('Name'));
        Assert.areEqual('25', row1.get('Age'));
        Assert.areEqual('', row1.get('Email'));

        Map<String, String> row2 = result[1];
        Assert.areEqual('Jane', row2.get('Name'));
        Assert.areEqual('', row2.get('Age'));
        Assert.areEqual('jane@example.com', row2.get('Email'));
    }

    @IsTest
    static void testSplitLinesChunking() {
        String csvData = '';
        for (Integer i = 0; i < 120000; i++) {
            csvData += 'Line' + i + '\n';
        }
        List<String> lines = DynamicCSVParser.splitLines(csvData, 50000);
        Assert.isTrue(lines.size() >= 120000, 'splitLines should handle large strings in chunks');
    }
}