/**
 * @description Utility class for handling field-level security and permissions
 * @author Blink AI
 * @version 1.0
 */
public with sharing class RelatedListSecurityUtils {
    
    /**
     * @description Check if user has read access to specific fields
     * @param objectApiName API name of the object
     * @param fieldNames List of field names to check
     * @return Map of field names to boolean access
     */
    public static Map<String, Boolean> checkFieldReadAccess(String objectApiName, List<String> fieldNames) {
        Map<String, Boolean> accessMap = new Map<String, Boolean>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                // If object doesn't exist, return false for all fields
                for (String fieldName : fieldNames) {
                    accessMap.put(fieldName, false);
                }
                return accessMap;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            for (String fieldName : fieldNames) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                    accessMap.put(fieldName, fieldDescribe.isAccessible());
                } else {
                    accessMap.put(fieldName, false);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error checking field read access: ' + e.getMessage());
            // Default to false for all fields on error
            for (String fieldName : fieldNames) {
                accessMap.put(fieldName, false);
            }
        }
        
        return accessMap;
    }
    
    /**
     * @description Check if user has update access to specific fields
     * @param objectApiName API name of the object
     * @param fieldNames List of field names to check
     * @return Map of field names to boolean access
     */
    public static Map<String, Boolean> checkFieldUpdateAccess(String objectApiName, List<String> fieldNames) {
        Map<String, Boolean> accessMap = new Map<String, Boolean>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                // If object doesn't exist, return false for all fields
                for (String fieldName : fieldNames) {
                    accessMap.put(fieldName, false);
                }
                return accessMap;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            for (String fieldName : fieldNames) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                    accessMap.put(fieldName, fieldDescribe.isUpdateable());
                } else {
                    accessMap.put(fieldName, false);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error checking field update access: ' + e.getMessage());
            // Default to false for all fields on error
            for (String fieldName : fieldNames) {
                accessMap.put(fieldName, false);
            }
        }
        
        return accessMap;
    }
    
    /**
     * @description Check if user has create access to an object
     * @param objectApiName API name of the object
     * @return Boolean indicating create access
     */
    public static Boolean checkObjectCreateAccess(String objectApiName) {
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return false;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            return objectDescribe.isCreateable();
            
        } catch (Exception e) {
            System.debug('Error checking object create access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Check if user has update access to an object
     * @param objectApiName API name of the object
     * @return Boolean indicating update access
     */
    public static Boolean checkObjectUpdateAccess(String objectApiName) {
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return false;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            return objectDescribe.isUpdateable();
            
        } catch (Exception e) {
            System.debug('Error checking object update access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Check if user has delete access to an object
     * @param objectApiName API name of the object
     * @return Boolean indicating delete access
     */
    public static Boolean checkObjectDeleteAccess(String objectApiName) {
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                return false;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            return objectDescribe.isDeletable();
            
        } catch (Exception e) {
            System.debug('Error checking object delete access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Filter fields based on user's read access
     * @param objectApiName API name of the object
     * @param fieldNames List of field names to filter
     * @return List of accessible field names
     */
    public static List<String> filterReadableFields(String objectApiName, List<String> fieldNames) {
        List<String> accessibleFields = new List<String>();
        Map<String, Boolean> accessMap = checkFieldReadAccess(objectApiName, fieldNames);
        
        for (String fieldName : fieldNames) {
            if (accessMap.get(fieldName) == true) {
                accessibleFields.add(fieldName);
            }
        }
        
        return accessibleFields;
    }
    
    /**
     * @description Filter fields based on user's update access
     * @param objectApiName API name of the object
     * @param fieldNames List of field names to filter
     * @return List of updateable field names
     */
    public static List<String> filterUpdateableFields(String objectApiName, List<String> fieldNames) {
        List<String> updateableFields = new List<String>();
        Map<String, Boolean> accessMap = checkFieldUpdateAccess(objectApiName, fieldNames);
        
        for (String fieldName : fieldNames) {
            if (accessMap.get(fieldName) == true) {
                updateableFields.add(fieldName);
            }
        }
        
        return updateableFields;
    }
    
    /**
     * @description Strip inaccessible fields from SObject records
     * @param records List of SObject records
     * @param objectApiName API name of the object
     * @param operation Type of operation (READ, UPDATE, CREATE, DELETE)
     * @return List of SObject records with accessible fields only
     */
    public static List<SObject> stripInaccessibleFields(List<SObject> records, String objectApiName, String operation) {
        try {
            if (records == null || records.isEmpty()) {
                return records;
            }
            
            // Use Security.stripInaccessible for enhanced security
            SObjectAccessDecision decision;
            
            if (operation == 'READ') {
                decision = Security.stripInaccessible(AccessType.READABLE, records);
            } else if (operation == 'UPDATE') {
                decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
            } else if (operation == 'CREATE') {
                decision = Security.stripInaccessible(AccessType.CREATABLE, records);
            } else {
                // Default to readable
                decision = Security.stripInaccessible(AccessType.READABLE, records);
            }
            
            return decision.getRecords();
            
        } catch (Exception e) {
            System.debug('Error stripping inaccessible fields: ' + e.getMessage());
            return records; // Return original records if stripping fails
        }
    }
    
    /**
     * @description Check if user has permission to perform bulk operations
     * @param objectApiName API name of the object
     * @param recordCount Number of records in bulk operation
     * @return Boolean indicating if bulk operation is allowed
     */
    public static Boolean checkBulkOperationPermission(String objectApiName, Integer recordCount) {
        try {
            // Check basic object permissions
            if (!checkObjectUpdateAccess(objectApiName)) {
                return false;
            }
            
            // Check if record count exceeds reasonable limits
            Integer maxBulkRecords = 200; // Configurable limit
            if (recordCount > maxBulkRecords) {
                return false;
            }
            
            // Additional custom permission checks can be added here
            // For example, check for custom permissions or profile-based restrictions
            
            return true;
            
        } catch (Exception e) {
            System.debug('Error checking bulk operation permission: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Get user's effective permissions for an object
     * @param objectApiName API name of the object
     * @return Map containing permission details
     */
    public static Map<String, Object> getUserObjectPermissions(String objectApiName) {
        Map<String, Object> permissions = new Map<String, Object>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                permissions.put('objectExists', false);
                permissions.put('canRead', false);
                permissions.put('canCreate', false);
                permissions.put('canUpdate', false);
                permissions.put('canDelete', false);
                return permissions;
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            
            permissions.put('objectExists', true);
            permissions.put('canRead', objectDescribe.isAccessible());
            permissions.put('canCreate', objectDescribe.isCreateable());
            permissions.put('canUpdate', objectDescribe.isUpdateable());
            permissions.put('canDelete', objectDescribe.isDeletable());
            permissions.put('objectLabel', objectDescribe.getLabel());
            permissions.put('objectLabelPlural', objectDescribe.getLabelPlural());
            
        } catch (Exception e) {
            System.debug('Error getting user object permissions: ' + e.getMessage());
            permissions.put('error', e.getMessage());
        }
        
        return permissions;
    }
    
    /**
     * @description Validate that user has required permissions for a field operation
     * @param objectApiName API name of the object
     * @param fieldName Name of the field
     * @param operation Type of operation (READ, UPDATE)
     * @return Boolean indicating if operation is allowed
     */
    public static Boolean validateFieldOperation(String objectApiName, String fieldName, String operation) {
        try {
            if (operation == 'READ') {
                Map<String, Boolean> readAccess = checkFieldReadAccess(objectApiName, new List<String>{fieldName});
                return readAccess.get(fieldName) == true;
            } else if (operation == 'UPDATE') {
                Map<String, Boolean> updateAccess = checkFieldUpdateAccess(objectApiName, new List<String>{fieldName});
                return updateAccess.get(fieldName) == true;
            }
            
            return false;
            
        } catch (Exception e) {
            System.debug('Error validating field operation: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Log security violations for audit purposes
     * @param userId User ID who attempted the operation
     * @param objectApiName API name of the object
     * @param operation Type of operation attempted
     * @param details Additional details about the violation
     */
    public static void logSecurityViolation(String userId, String objectApiName, String operation, String details) {
        try {
            // In a real implementation, you might want to:
            // 1. Insert records into a custom audit object
            // 2. Send platform events for real-time monitoring
            // 3. Integrate with external security systems
            
            System.debug(LoggingLevel.WARN, 
                'SECURITY VIOLATION - User: ' + userId + 
                ', Object: ' + objectApiName + 
                ', Operation: ' + operation + 
                ', Details: ' + details);
            
            // Example: Create a platform event for security monitoring
            // Security_Violation__e violation = new Security_Violation__e(
            //     User_Id__c = userId,
            //     Object_Name__c = objectApiName,
            //     Operation__c = operation,
            //     Details__c = details,
            //     Timestamp__c = DateTime.now()
            // );
            // EventBus.publish(violation);
            
        } catch (Exception e) {
            System.debug('Error logging security violation: ' + e.getMessage());
        }
    }
}