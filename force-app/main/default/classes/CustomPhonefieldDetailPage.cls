public with sharing class CustomPhonefieldDetailPage {
     public static void createCustomPhoneField() {
      MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();

        try {
            // Check if field already exists
            MetadataService.IReadResult readFieldResult = service.readMetadata('CustomField', new String[] { 'Account.New19_Phone_Field__c' });
            System.debug('readFieldResult: ' + JSON.serialize(readFieldResult));


            // Check if the read operation was successful and has records
           if (readFieldResult != null && 
                readFieldResult.getRecords() != null && 
                readFieldResult.getRecords().size() > 0 && 
                readFieldResult.getRecords()[0].fullName != null) {
                    System.debug(' Custom field already exists: Account.New19_Phone_Field__c');
                    return;  // Skip creation if exists
            }

            MetadataService.CustomField newField = new MetadataService.CustomField();
            newField.fullName = 'Account.New19_Phone_Field__c';
            newField.label = 'New19 Phone Field';
            newField.type_x = 'Phone';
            newField.description = 'A custom phone field to replace the standard one.';
            newField.required = false;

            MetadataService.SaveResult[] results = service.createMetadata(new MetadataService.Metadata[] { newField });

            if (results != null && results.size() > 0 && results[0].success) {
                System.debug('Custom field created successfully: ' + newField.fullName);
            } else {
                String errMsg = (results != null && results.size() > 0 && results[0].errors != null && results[0].errors.size() > 0)
                    ? results[0].errors[0].message
                    : 'Unknown error creating custom field.';
                System.debug('Error creating custom field: ' + errMsg);
            }
        } catch (Exception e) {
            System.debug(' Exception in createCustomPhoneField: ' + e.getMessage());
        }
    }
public static void replacePhoneFieldInLayout() {
    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
    service.SessionHeader = new MetadataService.SessionHeader_element();
    service.SessionHeader.sessionId = UserInfo.getSessionId();

    try {
        // Account layout fetch karo
        MetadataService.IReadResult readResult = service.readMetadata('Layout', new String[] { 'Account-Account(Sales) Layout' }); // 👈 exact layout name

        if (readResult == null || readResult.getRecords() == null || readResult.getRecords().isEmpty()) {
            System.debug('Layout not found.');
            return;
        }

        MetadataService.Layout layout = (MetadataService.Layout) readResult.getRecords()[0];
        Boolean replaced = false;

        // Layout sections traverse karo
        for (MetadataService.LayoutSection section : layout.layoutSections) {
            if (section.layoutColumns == null) continue;

            for (MetadataService.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems == null) continue;

                for (MetadataService.LayoutItem item : column.layoutItems) {
                    if (item.field != null && item.field.equalsIgnoreCase('Phone')) {
                        // Phone ko replace karo
                        item.field = 'New19_Phone_Field__c'; 
                        replaced = true;
                                                 }
                }
            }
        }

        // Agar Phone field nahi mili to Custom field add kar do
        if (!replaced) {
            MetadataService.LayoutItem newItem = new MetadataService.LayoutItem();
            newItem.field = 'New19_Phone_Field__c';
            layout.layoutSections[0].layoutColumns[0].layoutItems.add(newItem);
            System.debug('Added New19_Phone_Field__c in first section.');
        }

        // Save updated layout
        MetadataService.SaveResult[] results = service.updateMetadata(
            new MetadataService.Metadata[] { layout }
        );

        if (results != null && results.size() > 0 && results[0].success) {
            System.debug('Layout updated successfully ✅');
        } else {
            System.debug('Error: ' + results[0].errors[0].message);
        }

    } catch (Exception e) {
        System.debug('Exception: ' + e.getMessage());
    }
}
}