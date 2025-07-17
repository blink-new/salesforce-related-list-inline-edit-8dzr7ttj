/**
 * @description Apex controller for the Related List Inline Edit component
 * @author Blink AI
 * @version 1.0
 */
public with sharing class RelatedListInlineEditController {
    
    /**
     * @description Wrapper class for query results with pagination
     */
    public class QueryResult {
        @AuraEnabled public List<SObject> records { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Boolean hasMore { get; set; }
        
        public QueryResult() {
            this.records = new List<SObject>();
            this.totalCount = 0;
            this.pageNumber = 1;
            this.pageSize = 10;
            this.hasMore = false;
        }
    }
    
    /**
     * @description Wrapper class for field metadata
     */
    public class FieldMetadata {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Boolean required { get; set; }
        @AuraEnabled public Boolean editable { get; set; }
        @AuraEnabled public Boolean sortable { get; set; }
        @AuraEnabled public Boolean filterable { get; set; }
        @AuraEnabled public List<String> picklistValues { get; set; }
        @AuraEnabled public String referenceTo { get; set; }
        @AuraEnabled public Integer length { get; set; }
        @AuraEnabled public Integer precision { get; set; }
        @AuraEnabled public Integer scale { get; set; }
        
        public FieldMetadata() {
            this.picklistValues = new List<String>();
        }
    }
    
    /**
     * @description Wrapper class for validation results
     */
    public class ValidationResult {
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public Map<String, String> fieldErrors { get; set; }
        
        public ValidationResult() {
            this.isValid = true;
            this.errorMessage = '';
            this.fieldErrors = new Map<String, String>();
        }
    }
    
    /**
     * @description Get related records with pagination and filtering
     * @param parentId ID of the parent record
     * @param objectApiName API name of the related object
     * @param relationshipField Field that relates to the parent
     * @param fieldsToQuery Comma-separated list of fields to query
     * @param pageSize Number of records per page
     * @param pageNumber Current page number
     * @param sortField Field to sort by
     * @param sortDirection Sort direction (ASC or DESC)
     * @param searchTerm Search term for filtering
     * @return QueryResult with records and pagination info
     */
    @AuraEnabled(cacheable=true)
    public static QueryResult getRelatedRecords(
        String parentId,
        String objectApiName,
        String relationshipField,
        String fieldsToQuery,
        Integer pageSize,
        Integer pageNumber,
        String sortField,
        String sortDirection,
        String searchTerm
    ) {
        try {
            // Validate inputs
            if (String.isBlank(parentId) || String.isBlank(objectApiName) || String.isBlank(relationshipField)) {
                throw new AuraHandledException('Required parameters are missing');
            }
            
            // Sanitize and validate object and field names
            if (!isValidSObjectName(objectApiName)) {
                throw new AuraHandledException('Invalid object API name');
            }
            
            // Set defaults
            pageSize = pageSize != null ? pageSize : 10;
            pageNumber = pageNumber != null ? pageNumber : 1;
            sortField = String.isNotBlank(sortField) ? sortField : 'Name';
            sortDirection = String.isNotBlank(sortDirection) ? sortDirection.toUpperCase() : 'ASC';
            
            // Validate sort direction
            if (sortDirection != 'ASC' && sortDirection != 'DESC') {
                sortDirection = 'ASC';
            }
            
            // Build field list
            Set<String> fieldSet = new Set<String>();
            fieldSet.add('Id');
            
            if (String.isNotBlank(fieldsToQuery)) {
                for (String field : fieldsToQuery.split(',')) {
                    String trimmedField = field.trim();
                    if (String.isNotBlank(trimmedField) && isValidFieldName(trimmedField)) {
                        fieldSet.add(trimmedField);
                    }
                }
            }
            
            // Ensure sort field is included
            if (String.isNotBlank(sortField) && isValidFieldName(sortField)) {
                fieldSet.add(sortField);
            }
            
            // Build WHERE clause
            String whereClause = relationshipField + ' = :parentId';
            
            // Add search filter if provided
            if (String.isNotBlank(searchTerm)) {
                String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
                List<String> searchFields = getSearchableFields(objectApiName, new List<String>(fieldSet));
                
                if (!searchFields.isEmpty()) {
                    List<String> searchConditions = new List<String>();
                    for (String field : searchFields) {
                        searchConditions.add(field + ' LIKE :searchPattern');
                    }
                    whereClause += ' AND (' + String.join(searchConditions, ' OR ') + ')';
                }
            }
            
            // Build ORDER BY clause
            String orderByClause = sortField + ' ' + sortDirection + ' NULLS LAST';
            
            // Calculate offset
            Integer offset = (pageNumber - 1) * pageSize;
            
            // Build and execute count query
            String countQuery = 'SELECT COUNT() FROM ' + objectApiName + ' WHERE ' + whereClause;
            Integer totalCount = Database.countQuery(countQuery);
            
            // Build and execute main query
            String query = 'SELECT ' + String.join(new List<String>(fieldSet), ', ') +
                          ' FROM ' + objectApiName +
                          ' WHERE ' + whereClause +
                          ' ORDER BY ' + orderByClause +
                          ' LIMIT ' + pageSize +
                          ' OFFSET ' + offset;
            
            List<SObject> records = Database.query(query);
            
            // Build result
            QueryResult result = new QueryResult();
            result.records = records;
            result.totalCount = totalCount;
            result.pageNumber = pageNumber;
            result.pageSize = pageSize;
            result.hasMore = (offset + pageSize) < totalCount;
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get field metadata for an object
     * @param objectApiName API name of the object
     * @return List of FieldMetadata
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getFieldMetadata(String objectApiName) {
        try {
            if (!isValidSObjectName(objectApiName)) {
                throw new AuraHandledException('Invalid object API name');
            }
            
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            List<FieldMetadata> fieldMetadataList = new List<FieldMetadata>();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Skip system fields that shouldn't be displayed
                if (isSystemField(fieldName)) {
                    continue;
                }
                
                FieldMetadata metadata = new FieldMetadata();
                metadata.name = fieldDescribe.getName();
                metadata.label = fieldDescribe.getLabel();
                metadata.type = String.valueOf(fieldDescribe.getType());
                metadata.required = !fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate();
                metadata.editable = fieldDescribe.isUpdateable();
                metadata.sortable = fieldDescribe.isSortable();
                metadata.filterable = fieldDescribe.isFilterable();
                metadata.length = fieldDescribe.getLength();
                metadata.precision = fieldDescribe.getPrecision();
                metadata.scale = fieldDescribe.getScale();
                
                // Get picklist values
                if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || 
                    fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                    for (Schema.PicklistEntry entry : picklistEntries) {
                        if (entry.isActive()) {
                            metadata.picklistValues.add(entry.getValue());
                        }
                    }
                }
                
                // Get reference information
                if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    List<Schema.sObjectType> referenceTo = fieldDescribe.getReferenceTo();
                    if (!referenceTo.isEmpty()) {
                        metadata.referenceTo = referenceTo[0].getDescribe().getName();
                    }
                }
                
                fieldMetadataList.add(metadata);
            }
            
            return fieldMetadataList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving field metadata: ' + e.getMessage());
        }
    }
    
    /**
     * @description Save records with validation
     * @param records List of records to save
     * @param objectApiName API name of the object
     * @return List of saved records
     */
    @AuraEnabled
    public static List<SObject> saveRecords(List<SObject> records, String objectApiName) {
        try {
            if (records == null || records.isEmpty()) {
                throw new AuraHandledException('No records to save');
            }
            
            if (!isValidSObjectName(objectApiName)) {
                throw new AuraHandledException('Invalid object API name');
            }
            
            // Validate records before saving
            ValidationResult validation = validateRecords(records, objectApiName);
            if (!validation.isValid) {
                throw new AuraHandledException(validation.errorMessage);
            }
            
            // Save records
            List<Database.SaveResult> saveResults = Database.update(records, false);
            
            // Check for errors
            List<String> errors = new List<String>();
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult result = saveResults[i];
                if (!result.isSuccess()) {
                    String recordError = 'Record ' + (i + 1) + ': ';
                    for (Database.Error error : result.getErrors()) {
                        recordError += error.getMessage() + '; ';
                    }
                    errors.add(recordError);
                }
            }
            
            if (!errors.isEmpty()) {
                throw new AuraHandledException('Save errors: ' + String.join(errors, ' '));
            }
            
            return records;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Delete records
     * @param recordIds List of record IDs to delete
     * @param objectApiName API name of the object
     */
    @AuraEnabled
    public static void deleteRecords(List<String> recordIds, String objectApiName) {
        try {
            if (recordIds == null || recordIds.isEmpty()) {
                throw new AuraHandledException('No records to delete');
            }
            
            if (!isValidSObjectName(objectApiName)) {
                throw new AuraHandledException('Invalid object API name');
            }
            
            // Query records to delete
            String query = 'SELECT Id FROM ' + objectApiName + ' WHERE Id IN :recordIds';
            List<SObject> recordsToDelete = Database.query(query);
            
            if (recordsToDelete.isEmpty()) {
                throw new AuraHandledException('No records found to delete');
            }
            
            // Delete records
            List<Database.DeleteResult> deleteResults = Database.delete(recordsToDelete, false);
            
            // Check for errors
            List<String> errors = new List<String>();
            for (Integer i = 0; i < deleteResults.size(); i++) {
                Database.DeleteResult result = deleteResults[i];
                if (!result.isSuccess()) {
                    String recordError = 'Record ' + recordIds[i] + ': ';
                    for (Database.Error error : result.getErrors()) {
                        recordError += error.getMessage() + '; ';
                    }
                    errors.add(recordError);
                }
            }
            
            if (!errors.isEmpty()) {
                throw new AuraHandledException('Delete errors: ' + String.join(errors, ' '));
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validate records before saving
     * @param records List of records to validate
     * @param objectApiName API name of the object
     * @return ValidationResult
     */
    @AuraEnabled
    public static ValidationResult validateRecords(List<SObject> records, String objectApiName) {
        ValidationResult result = new ValidationResult();
        
        try {
            if (records == null || records.isEmpty()) {
                result.isValid = false;
                result.errorMessage = 'No records to validate';
                return result;
            }
            
            if (!isValidSObjectName(objectApiName)) {
                result.isValid = false;
                result.errorMessage = 'Invalid object API name';
                return result;
            }
            
            // Get object metadata
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            // Validate each record
            for (Integer i = 0; i < records.size(); i++) {
                SObject record = records[i];
                Map<String, Object> fieldValues = record.getPopulatedFieldsAsMap();
                
                for (String fieldName : fieldValues.keySet()) {
                    if (!fieldMap.containsKey(fieldName.toLowerCase())) {
                        continue; // Skip unknown fields
                    }
                    
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                    Object fieldValue = fieldValues.get(fieldName);
                    
                    // Check required fields
                    if (!fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate() && fieldValue == null) {
                        result.isValid = false;
                        result.fieldErrors.put(fieldName, 'This field is required');
                    }
                    
                    // Check field length for text fields
                    if (fieldValue != null && fieldDescribe.getType() == Schema.DisplayType.STRING) {
                        String stringValue = String.valueOf(fieldValue);
                        if (stringValue.length() > fieldDescribe.getLength()) {
                            result.isValid = false;
                            result.fieldErrors.put(fieldName, 'Value exceeds maximum length of ' + fieldDescribe.getLength());
                        }
                    }
                    
                    // Check picklist values
                    if (fieldValue != null && (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || 
                                             fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST)) {
                        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                        Set<String> validValues = new Set<String>();
                        for (Schema.PicklistEntry entry : picklistEntries) {
                            if (entry.isActive()) {
                                validValues.add(entry.getValue());
                            }
                        }
                        
                        String picklistValue = String.valueOf(fieldValue);
                        if (!validValues.contains(picklistValue)) {
                            result.isValid = false;
                            result.fieldErrors.put(fieldName, 'Invalid picklist value: ' + picklistValue);
                        }
                    }
                }
            }
            
            if (!result.isValid && result.fieldErrors.isEmpty()) {
                result.errorMessage = 'Validation failed';
            } else if (!result.isValid) {
                List<String> errorMessages = new List<String>();
                for (String field : result.fieldErrors.keySet()) {
                    errorMessages.add(field + ': ' + result.fieldErrors.get(field));
                }
                result.errorMessage = String.join(errorMessages, '; ');
            }
            
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Validation error: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Bulk update records with specified field values
     * @param recordIds List of record IDs to update
     * @param fieldValues Map of field names to values
     * @param objectApiName API name of the object
     */
    @AuraEnabled
    public static void bulkUpdateRecords(List<String> recordIds, Map<String, Object> fieldValues, String objectApiName) {
        try {
            if (recordIds == null || recordIds.isEmpty()) {
                throw new AuraHandledException('No records to update');
            }
            
            if (fieldValues == null || fieldValues.isEmpty()) {
                throw new AuraHandledException('No field values provided');
            }
            
            if (!isValidSObjectName(objectApiName)) {
                throw new AuraHandledException('Invalid object API name');
            }
            
            // Query existing records
            String query = 'SELECT Id FROM ' + objectApiName + ' WHERE Id IN :recordIds';
            List<SObject> recordsToUpdate = Database.query(query);
            
            if (recordsToUpdate.isEmpty()) {
                throw new AuraHandledException('No records found to update');
            }
            
            // Update field values
            for (SObject record : recordsToUpdate) {
                for (String fieldName : fieldValues.keySet()) {
                    if (isValidFieldName(fieldName)) {
                        record.put(fieldName, fieldValues.get(fieldName));
                    }
                }
            }
            
            // Validate and save
            ValidationResult validation = validateRecords(recordsToUpdate, objectApiName);
            if (!validation.isValid) {
                throw new AuraHandledException(validation.errorMessage);
            }
            
            List<Database.SaveResult> saveResults = Database.update(recordsToUpdate, false);
            
            // Check for errors
            List<String> errors = new List<String>();
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult result = saveResults[i];
                if (!result.isSuccess()) {
                    String recordError = 'Record ' + recordIds[i] + ': ';
                    for (Database.Error error : result.getErrors()) {
                        recordError += error.getMessage() + '; ';
                    }
                    errors.add(recordError);
                }
            }
            
            if (!errors.isEmpty()) {
                throw new AuraHandledException('Bulk update errors: ' + String.join(errors, ' '));
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error in bulk update: ' + e.getMessage());
        }
    }
    
    // Helper methods
    
    /**
     * @description Check if an SObject name is valid
     * @param objectName Name to validate
     * @return Boolean indicating if valid
     */
    private static Boolean isValidSObjectName(String objectName) {
        if (String.isBlank(objectName)) {
            return false;
        }
        
        // Check if object exists in global describe
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        return globalDescribe.containsKey(objectName);
    }
    
    /**
     * @description Check if a field name is valid
     * @param fieldName Name to validate
     * @return Boolean indicating if valid
     */
    private static Boolean isValidFieldName(String fieldName) {
        if (String.isBlank(fieldName)) {
            return false;
        }
        
        // Basic validation - alphanumeric, underscores, and dots allowed
        Pattern fieldPattern = Pattern.compile('^[a-zA-Z][a-zA-Z0-9_\\.]*$');
        return fieldPattern.matcher(fieldName).matches();
    }
    
    /**
     * @description Check if a field is a system field that should be hidden
     * @param fieldName Name of the field
     * @return Boolean indicating if it's a system field
     */
    private static Boolean isSystemField(String fieldName) {
        Set<String> systemFields = new Set<String>{
            'createdbyid', 'createddate', 'lastmodifiedbyid', 'lastmodifieddate',
            'systemmodstamp', 'isdeleted', 'lastactivitydate', 'lastreferenceddate',
            'lastvieweddate', 'ownerid'
        };
        
        return systemFields.contains(fieldName.toLowerCase());
    }
    
    /**
     * @description Get searchable fields from a list of fields
     * @param objectApiName API name of the object
     * @param fieldNames List of field names to check
     * @return List of searchable field names
     */
    private static List<String> getSearchableFields(String objectApiName, List<String> fieldNames) {
        List<String> searchableFields = new List<String>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            for (String fieldName : fieldNames) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                    
                    // Only include text-based fields for searching
                    if (fieldDescribe.getType() == Schema.DisplayType.STRING ||
                        fieldDescribe.getType() == Schema.DisplayType.TEXTAREA ||
                        fieldDescribe.getType() == Schema.DisplayType.EMAIL ||
                        fieldDescribe.getType() == Schema.DisplayType.PHONE ||
                        fieldDescribe.getType() == Schema.DisplayType.URL) {
                        searchableFields.add(fieldName);
                    }
                }
            }
        } catch (Exception e) {
            // If there's an error, return empty list
            System.debug('Error getting searchable fields: ' + e.getMessage());
        }
        
        return searchableFields;
    }
}