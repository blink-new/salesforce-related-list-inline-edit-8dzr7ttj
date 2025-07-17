# API Documentation

## Component Props

### RelatedListInlineEdit

The main component for rendering an inline-editable related list.

```typescript
interface RelatedListInlineEditProps {
  config: RelatedListConfig;
  records: SalesforceRecord[];
  onSave: (records: SalesforceRecord[]) => Promise<void>;
  onDelete: (recordIds: string[]) => Promise<void>;
  onRefresh: () => Promise<void>;
  loading?: boolean;
}
```

#### Props Details

##### `config: RelatedListConfig`
Configuration object that defines the behavior and appearance of the related list.

**Required**: Yes

**Example**:
```typescript
const config: RelatedListConfig = {
  objectName: 'Contact',
  title: 'Contacts',
  allowCreate: true,
  allowEdit: true,
  allowDelete: true,
  pageSize: 25,
  sortField: 'name',
  sortDirection: 'asc',
  fields: [
    // ... field definitions
  ]
};
```

##### `records: SalesforceRecord[]`
Array of records to display in the related list.

**Required**: Yes

**Example**:
```typescript
const records: SalesforceRecord[] = [
  {
    id: '003000000000001',
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+1-555-0123',
    isDirty: false,
    isNew: false
  },
  // ... more records
];
```

##### `onSave: (records: SalesforceRecord[]) => Promise<void>`
Callback function called when records need to be saved.

**Required**: Yes

**Parameters**:
- `records`: Array of modified records that need to be saved

**Example**:
```typescript
const handleSave = async (records: SalesforceRecord[]) => {
  try {
    for (const record of records) {
      if (record.isNew) {
        await createRecord(record);
      } else {
        await updateRecord(record);
      }
    }
    // Refresh the data after successful save
    await refreshData();
  } catch (error) {
    console.error('Save failed:', error);
    throw error; // Re-throw to let component handle error state
  }
};
```

##### `onDelete: (recordIds: string[]) => Promise<void>`
Callback function called when records need to be deleted.

**Required**: Yes

**Parameters**:
- `recordIds`: Array of record IDs to delete

**Example**:
```typescript
const handleDelete = async (recordIds: string[]) => {
  try {
    await Promise.all(recordIds.map(id => deleteRecord(id)));
    // Refresh the data after successful deletion
    await refreshData();
  } catch (error) {
    console.error('Delete failed:', error);
    throw error;
  }
};
```

##### `onRefresh: () => Promise<void>`
Callback function called when the user triggers a data refresh.

**Required**: Yes

**Example**:
```typescript
const handleRefresh = async () => {
  try {
    const freshData = await fetchRecords();
    setRecords(freshData);
  } catch (error) {
    console.error('Refresh failed:', error);
    throw error;
  }
};
```

##### `loading?: boolean`
Indicates whether the component should show loading state.

**Required**: No  
**Default**: `false`

## Type Definitions

### RelatedListConfig

Configuration object for the related list component.

```typescript
interface RelatedListConfig {
  objectName: string;
  title: string;
  fields: SalesforceField[];
  allowCreate: boolean;
  allowEdit: boolean;
  allowDelete: boolean;
  pageSize: number;
  sortField?: string;
  sortDirection?: 'asc' | 'desc';
}
```

#### Properties

- **`objectName`**: Salesforce object API name (e.g., 'Contact', 'Account')
- **`title`**: Display title shown in the component header
- **`fields`**: Array of field configurations defining columns
- **`allowCreate`**: Whether users can create new records
- **`allowEdit`**: Whether users can edit existing records
- **`allowDelete`**: Whether users can delete records
- **`pageSize`**: Number of records to display per page
- **`sortField`**: Default field to sort by (optional)
- **`sortDirection`**: Default sort direction (optional)

### SalesforceField

Configuration for individual fields/columns.

```typescript
interface SalesforceField {
  id: string;
  name: string;
  label: string;
  type: FieldType;
  required: boolean;
  editable: boolean;
  visible: boolean;
  sortable: boolean;
  filterable: boolean;
  width?: number;
  picklistValues?: string[];
  lookupObject?: string;
  validation?: ValidationRule;
}
```

#### Properties

- **`id`**: Unique identifier for the field
- **`name`**: Field API name used for data access
- **`label`**: Display label shown in column header
- **`type`**: Data type of the field (see FieldType)
- **`required`**: Whether the field is required for record creation/editing
- **`editable`**: Whether the field can be edited inline
- **`visible`**: Whether the field is displayed as a column
- **`sortable`**: Whether the column can be sorted
- **`filterable`**: Whether the column can be filtered
- **`width`**: Column width in pixels (optional)
- **`picklistValues`**: Available options for picklist fields (optional)
- **`lookupObject`**: Target object for lookup fields (optional)
- **`validation`**: Custom validation rules (optional)

### FieldType

Supported field data types.

```typescript
type FieldType = 
  | 'text'
  | 'textarea'
  | 'number'
  | 'currency'
  | 'date'
  | 'datetime'
  | 'email'
  | 'phone'
  | 'url'
  | 'checkbox'
  | 'picklist'
  | 'lookup';
```

#### Field Type Details

##### `text`
Single-line text input.
- **Editor**: `<Input type="text" />`
- **Display**: Plain text
- **Validation**: Optional pattern matching

##### `textarea`
Multi-line text input.
- **Editor**: `<Textarea />`
- **Display**: Truncated text with expand option
- **Validation**: Optional length limits

##### `number`
Numeric input.
- **Editor**: `<Input type="number" />`
- **Display**: Formatted number
- **Validation**: Min/max value validation

##### `currency`
Currency input with formatting.
- **Editor**: `<Input type="number" />`
- **Display**: Formatted as currency (e.g., $1,234.56)
- **Validation**: Positive values, decimal precision

##### `date`
Date picker.
- **Editor**: `<Input type="date" />`
- **Display**: Formatted date
- **Validation**: Date range validation

##### `datetime`
Date and time picker.
- **Editor**: `<Input type="datetime-local" />`
- **Display**: Formatted date and time
- **Validation**: Date/time range validation

##### `email`
Email input with validation.
- **Editor**: `<Input type="email" />`
- **Display**: Email address with mailto link
- **Validation**: Email format validation

##### `phone`
Phone number input.
- **Editor**: `<Input type="tel" />`
- **Display**: Formatted phone number
- **Validation**: Phone format validation

##### `url`
URL input with validation.
- **Editor**: `<Input type="url" />`
- **Display**: Clickable link
- **Validation**: URL format validation

##### `checkbox`
Boolean checkbox.
- **Editor**: `<Checkbox />`
- **Display**: Checked/unchecked indicator
- **Validation**: None

##### `picklist`
Dropdown selection.
- **Editor**: `<Select />` with predefined options
- **Display**: Selected value
- **Validation**: Must be one of the allowed values
- **Required**: `picklistValues` array

##### `lookup`
Reference to another Salesforce object.
- **Editor**: Searchable dropdown or modal
- **Display**: Related record name with link
- **Validation**: Must reference existing record
- **Required**: `lookupObject` property

### SalesforceRecord

Data structure for individual records.

```typescript
interface SalesforceRecord {
  id: string;
  [key: string]: any;
  isNew?: boolean;
  isDirty?: boolean;
  errors?: Record<string, string>;
}
```

#### Properties

- **`id`**: Unique record identifier (Salesforce ID)
- **`[key: string]: any`**: Dynamic field values based on field configuration
- **`isNew`**: Indicates if this is a newly created record (optional)
- **`isDirty`**: Indicates if the record has unsaved changes (optional)
- **`errors`**: Field-level error messages (optional)

### ValidationRule

Custom validation configuration for fields.

```typescript
interface ValidationRule {
  min?: number;
  max?: number;
  pattern?: string;
  message?: string;
}
```

#### Properties

- **`min`**: Minimum value (for numbers) or length (for text)
- **`max`**: Maximum value (for numbers) or length (for text)
- **`pattern`**: Regular expression pattern for validation
- **`message`**: Custom error message to display on validation failure

### EditState

Internal state tracking for inline editing.

```typescript
interface EditState {
  recordId: string;
  fieldName: string;
  value: any;
  originalValue: any;
}
```

#### Properties

- **`recordId`**: ID of the record being edited
- **`fieldName`**: Name of the field being edited
- **`value`**: Current edited value
- **`originalValue`**: Original value before editing

### ValidationResult

Result of field validation.

```typescript
interface ValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}
```

#### Properties

- **`isValid`**: Whether all validations passed
- **`errors`**: Map of field names to error messages

## Events and Callbacks

### Save Events

The `onSave` callback is triggered in the following scenarios:

1. **Single Cell Edit**: When user saves an individual cell edit
2. **Bulk Edit**: When user applies bulk changes to multiple records
3. **New Record**: When user creates a new record

### Delete Events

The `onDelete` callback is triggered when:

1. **Single Record Delete**: User deletes individual record
2. **Bulk Delete**: User deletes multiple selected records

### Refresh Events

The `onRefresh` callback is triggered when:

1. **Manual Refresh**: User clicks the refresh button
2. **Auto Refresh**: Component automatically refreshes after certain operations

## Error Handling

### Error States

The component handles various error states:

1. **Validation Errors**: Field-level validation failures
2. **Save Errors**: Failures during record save operations
3. **Delete Errors**: Failures during record deletion
4. **Network Errors**: Connection or API failures

### Error Display

Errors are displayed in multiple ways:

1. **Inline Errors**: Field-level errors shown next to inputs
2. **Toast Notifications**: Global error messages
3. **Record Highlighting**: Visual indicators for records with errors
4. **Loading States**: Disabled states during error recovery

## Performance Considerations

### Optimization Features

1. **Virtual Scrolling**: Automatically enabled for large datasets
2. **Debounced Updates**: Prevents excessive API calls during typing
3. **Memoized Renders**: Optimized re-rendering for better performance
4. **Lazy Loading**: Fields and data loaded on demand

### Best Practices

1. **Pagination**: Use reasonable page sizes (25-100 records)
2. **Field Limiting**: Only include necessary fields in configuration
3. **Async Operations**: Always handle save/delete operations asynchronously
4. **Error Boundaries**: Implement error boundaries for graceful failure handling

## Accessibility

### WCAG Compliance

The component follows WCAG 2.1 AA guidelines:

1. **Keyboard Navigation**: Full keyboard support
2. **Screen Reader Support**: Proper ARIA labels and roles
3. **Color Contrast**: Meets contrast requirements
4. **Focus Management**: Logical focus order and indicators

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Save current edit |
| `Escape` | Cancel current edit |
| `Tab` | Navigate to next field |
| `Shift + Tab` | Navigate to previous field |
| `Space` | Toggle checkbox fields |
| `Ctrl/Cmd + A` | Select all records |

## Integration Examples

### Salesforce Lightning Web Component

```javascript
// lwc/relatedListContainer/relatedListContainer.js
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RelatedListContainer extends LightningElement {
    @api recordId;
    @api objectApiName;
    
    @track records = [];
    @track loading = false;
    
    config = {
        objectName: 'Contact',
        title: 'Contacts',
        allowCreate: true,
        allowEdit: true,
        allowDelete: true,
        pageSize: 25,
        fields: [
            // ... field configuration
        ]
    };
    
    async handleSave(records) {
        this.loading = true;
        try {
            // Use Salesforce APIs to save records
            await this.saveRecords(records);
            this.showToast('Success', 'Records saved successfully', 'success');
        } catch (error) {
            this.showToast('Error', error.message, 'error');
        } finally {
            this.loading = false;
        }
    }
    
    async handleDelete(recordIds) {
        // Implementation for delete
    }
    
    async handleRefresh() {
        // Implementation for refresh
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}
```

### React with Salesforce REST API

```typescript
import React, { useState, useEffect } from 'react';
import { RelatedListInlineEdit } from './components/RelatedListInlineEdit';

const SalesforceRelatedList: React.FC = () => {
    const [records, setRecords] = useState<SalesforceRecord[]>([]);
    const [loading, setLoading] = useState(false);
    
    const config: RelatedListConfig = {
        // ... configuration
    };
    
    const handleSave = async (records: SalesforceRecord[]) => {
        const promises = records.map(record => {
            if (record.isNew) {
                return fetch('/api/salesforce/sobjects/Contact', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(record)
                });
            } else {
                return fetch(`/api/salesforce/sobjects/Contact/${record.id}`, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(record)
                });
            }
        });
        
        await Promise.all(promises);
        await refreshData();
    };
    
    const handleDelete = async (recordIds: string[]) => {
        const promises = recordIds.map(id =>
            fetch(`/api/salesforce/sobjects/Contact/${id}`, {
                method: 'DELETE'
            })
        );
        
        await Promise.all(promises);
        await refreshData();
    };
    
    const refreshData = async () => {
        setLoading(true);
        try {
            const response = await fetch('/api/salesforce/query?q=SELECT Id, Name, Email FROM Contact');
            const data = await response.json();
            setRecords(data.records);
        } finally {
            setLoading(false);
        }
    };
    
    useEffect(() => {
        refreshData();
    }, []);
    
    return (
        <RelatedListInlineEdit
            config={config}
            records={records}
            onSave={handleSave}
            onDelete={handleDelete}
            onRefresh={refreshData}
            loading={loading}
        />
    );
};
```