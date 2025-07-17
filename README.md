# Salesforce Related List Inline Edit Component

A fully configurable inline edit component for Salesforce related lists with comprehensive editing features and seamless integration capabilities.

![Component Preview](https://img.shields.io/badge/React-18+-blue.svg)
![TypeScript](https://img.shields.io/badge/TypeScript-5+-blue.svg)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-3+-blue.svg)

## 🚀 Features

### Core Functionality
- **Inline Cell Editing**: Click-to-edit functionality for all supported field types
- **Multiple Field Types**: Support for text, number, date, picklist, lookup, checkbox, currency, email, phone, URL, and textarea fields
- **Real-time Validation**: Field-level validation with error display
- **Bulk Operations**: Edit multiple records simultaneously
- **Mass Actions**: Delete, update, and clone multiple records
- **Auto-save**: Automatic saving with conflict detection
- **Undo/Redo**: Full undo/redo functionality for all operations

### Advanced Features
- **Configurable Columns**: Show/hide columns and customize field ordering
- **Custom Field Types**: Extensible field type system
- **Keyboard Navigation**: Full keyboard support with shortcuts
- **Responsive Design**: Mobile and desktop optimized
- **Export Functionality**: Export data in multiple formats
- **Advanced Filtering**: Complex filtering and sorting capabilities
- **Field-level Permissions**: Granular permission control
- **Custom Validation Rules**: Define custom validation logic

### User Experience
- **Loading States**: Comprehensive loading indicators
- **Error Handling**: Graceful error handling with user feedback
- **Context Menus**: Right-click context menus for quick actions
- **Tooltips**: Helpful tooltips throughout the interface
- **Visual Feedback**: Clear visual indicators for dirty records and selections

## 📦 Installation

```bash
npm install
```

## 🛠️ Usage

### Basic Implementation

```tsx
import { RelatedListInlineEdit } from './components/RelatedListInlineEdit';
import { RelatedListConfig, SalesforceRecord } from './types/salesforce';

const config: RelatedListConfig = {
  objectName: 'Contact',
  title: 'Contacts',
  allowCreate: true,
  allowEdit: true,
  allowDelete: true,
  pageSize: 25,
  fields: [
    {
      id: 'name',
      name: 'name',
      label: 'Name',
      type: 'text',
      required: true,
      editable: true,
      visible: true,
      sortable: true,
      filterable: true,
      width: 200
    },
    {
      id: 'email',
      name: 'email',
      label: 'Email',
      type: 'email',
      required: false,
      editable: true,
      visible: true,
      sortable: true,
      filterable: true,
      width: 250
    }
    // ... more fields
  ]
};

const records: SalesforceRecord[] = [
  {
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '+1-555-0123'
  }
  // ... more records
];

function MyComponent() {
  const handleSave = async (records: SalesforceRecord[]) => {
    // Implement save logic
    console.log('Saving records:', records);
  };

  const handleDelete = async (recordIds: string[]) => {
    // Implement delete logic
    console.log('Deleting records:', recordIds);
  };

  const handleRefresh = async () => {
    // Implement refresh logic
    console.log('Refreshing data');
  };

  return (
    <RelatedListInlineEdit
      config={config}
      records={records}
      onSave={handleSave}
      onDelete={handleDelete}
      onRefresh={handleRefresh}
      loading={false}
    />
  );
}
```

## 📋 API Reference

### Props

#### `RelatedListInlineEditProps`

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `config` | `RelatedListConfig` | ✅ | Configuration object defining the related list behavior |
| `records` | `SalesforceRecord[]` | ✅ | Array of records to display and edit |
| `onSave` | `(records: SalesforceRecord[]) => Promise<void>` | ✅ | Callback function called when records are saved |
| `onDelete` | `(recordIds: string[]) => Promise<void>` | ✅ | Callback function called when records are deleted |
| `onRefresh` | `() => Promise<void>` | ✅ | Callback function called when refresh is triggered |
| `loading` | `boolean` | ❌ | Loading state indicator (default: false) |

### Type Definitions

#### `RelatedListConfig`

```typescript
interface RelatedListConfig {
  objectName: string;           // Salesforce object API name
  title: string;               // Display title for the related list
  fields: SalesforceField[];   // Array of field configurations
  allowCreate: boolean;        // Enable record creation
  allowEdit: boolean;          // Enable record editing
  allowDelete: boolean;        // Enable record deletion
  pageSize: number;           // Number of records per page
  sortField?: string;         // Default sort field
  sortDirection?: 'asc' | 'desc'; // Default sort direction
}
```

#### `SalesforceField`

```typescript
interface SalesforceField {
  id: string;                  // Unique field identifier
  name: string;               // Field API name
  label: string;              // Display label
  type: FieldType;            // Field data type
  required: boolean;          // Whether field is required
  editable: boolean;          // Whether field can be edited
  visible: boolean;           // Whether field is visible
  sortable: boolean;          // Whether field can be sorted
  filterable: boolean;        // Whether field can be filtered
  width?: number;             // Column width in pixels
  picklistValues?: string[];  // Options for picklist fields
  lookupObject?: string;      // Target object for lookup fields
  validation?: ValidationRule; // Custom validation rules
}
```

#### `SalesforceRecord`

```typescript
interface SalesforceRecord {
  id: string;                 // Unique record identifier
  [key: string]: any;         // Dynamic field values
  isNew?: boolean;            // Whether record is newly created
  isDirty?: boolean;          // Whether record has unsaved changes
  errors?: Record<string, string>; // Field-level error messages
}
```

#### Supported Field Types

```typescript
type FieldType = 
  | 'text'      // Single-line text input
  | 'textarea'  // Multi-line text input
  | 'number'    // Numeric input
  | 'currency'  // Currency input with formatting
  | 'date'      // Date picker
  | 'datetime'  // Date and time picker
  | 'email'     // Email input with validation
  | 'phone'     // Phone number input
  | 'url'       // URL input with validation
  | 'checkbox'  // Boolean checkbox
  | 'picklist'  // Dropdown selection
  | 'lookup';   // Lookup to another object
```

## 🎨 Styling and Theming

The component uses Tailwind CSS and follows Salesforce Lightning Design System principles. Key design tokens:

### Colors
- **Primary**: `#0176D3` (Salesforce Blue)
- **Accent**: `#FF6B35` (Action Orange)
- **Background**: `#FAFBFC` (Light Gray)
- **Dark Mode**: `#16181D` (Dark Background)

### Typography
- **Primary Font**: Inter
- **Weight**: Inter Medium for emphasis

### Customization

You can customize the appearance by modifying the Tailwind classes or overriding CSS variables:

```css
:root {
  --primary-color: #0176D3;
  --accent-color: #FF6B35;
  --background-color: #FAFBFC;
  --text-color: #181818;
}
```

## 🔧 Advanced Configuration

### Custom Field Types

Extend the component with custom field types:

```typescript
// Add to the renderFieldEditor function
case 'custom-rating':
  return (
    <CustomRatingComponent
      value={value}
      onChange={onChange}
      max={5}
    />
  );
```

### Validation Rules

Define custom validation for fields:

```typescript
const fieldWithValidation: SalesforceField = {
  id: 'email',
  name: 'email',
  label: 'Email Address',
  type: 'email',
  required: true,
  editable: true,
  visible: true,
  sortable: true,
  filterable: true,
  validation: {
    pattern: '^[^@]+@[^@]+\\.[^@]+$',
    message: 'Please enter a valid email address'
  }
};
```

### Bulk Operations

The component supports bulk operations out of the box:

1. **Select Records**: Use checkboxes to select multiple records
2. **Bulk Edit**: Click "Bulk Edit" to modify multiple records simultaneously
3. **Mass Delete**: Select records and click "Delete" to remove multiple records

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Save current edit |
| `Escape` | Cancel current edit |
| `Tab` | Navigate to next editable field |
| `Shift + Tab` | Navigate to previous editable field |
| `Ctrl/Cmd + A` | Select all records |
| `Delete` | Delete selected records |

## 🧪 Testing

The component includes comprehensive test coverage. Run tests with:

```bash
npm test
```

### Test Categories
- **Unit Tests**: Individual component functionality
- **Integration Tests**: Component interaction with props
- **Accessibility Tests**: WCAG compliance
- **Performance Tests**: Rendering performance with large datasets

## 🚀 Performance Optimization

### Large Datasets
- **Virtual Scrolling**: Automatically enabled for 1000+ records
- **Lazy Loading**: Fields loaded on demand
- **Debounced Updates**: Prevents excessive API calls

### Memory Management
- **Cleanup**: Automatic cleanup of event listeners
- **Memoization**: React.memo and useMemo for expensive operations
- **Efficient Re-renders**: Optimized state updates

## 🔒 Security Considerations

### Data Validation
- **Client-side Validation**: Immediate feedback for users
- **Server-side Validation**: Always validate on the backend
- **XSS Protection**: All user input is sanitized

### Permissions
- **Field-level Security**: Respect Salesforce field permissions
- **Record-level Security**: Honor sharing rules and permissions
- **Action Permissions**: Control create/edit/delete capabilities

## 🐛 Troubleshooting

### Common Issues

#### Records Not Saving
- Verify `onSave` callback is properly implemented
- Check network requests in browser dev tools
- Ensure proper error handling in save function

#### Fields Not Editable
- Check `editable: true` in field configuration
- Verify user has edit permissions
- Ensure field type is supported

#### Performance Issues
- Enable virtual scrolling for large datasets
- Implement proper pagination
- Use React DevTools Profiler to identify bottlenecks

### Debug Mode

Enable debug logging:

```typescript
// Add to your component
const DEBUG = process.env.NODE_ENV === 'development';

if (DEBUG) {
  console.log('RelatedList Config:', config);
  console.log('Records:', records);
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Setup

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Salesforce Lightning Design System](https://www.lightningdesignsystem.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Radix UI](https://www.radix-ui.com/)
- [Lucide Icons](https://lucide.dev/)

## 📞 Support

For support and questions:
- 📧 Email: support@example.com
- 💬 Discord: [Join our community](https://discord.gg/example)
- 📖 Documentation: [Full docs](https://docs.example.com)
- 🐛 Issues: [GitHub Issues](https://github.com/example/repo/issues)