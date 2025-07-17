export interface SalesforceField {
  id: string;
  name: string;
  label: string;
  type: 'text' | 'number' | 'date' | 'datetime' | 'picklist' | 'lookup' | 'checkbox' | 'currency' | 'email' | 'phone' | 'url' | 'textarea';
  required: boolean;
  editable: boolean;
  visible: boolean;
  sortable: boolean;
  filterable: boolean;
  width?: number;
  picklistValues?: string[];
  lookupObject?: string;
  validation?: {
    min?: number;
    max?: number;
    pattern?: string;
    message?: string;
  };
  accessLevel?: 'read' | 'edit' | 'admin';
  requiredPermission?: string;
}

export interface SalesforceRecord {
  id: string;
  [key: string]: any;
  isNew?: boolean;
  isDirty?: boolean;
  errors?: Record<string, string>;
}

export interface UserPermissions {
  canCreate: boolean;
  canEdit: boolean;
  canDelete: boolean;
  canBulkEdit: boolean;
  canBulkDelete: boolean;
  fieldPermissions: Record<string, 'read' | 'edit' | 'none'>;
  customPermissions: string[];
  accessLevel: 'read' | 'edit' | 'admin';
}

export interface RelatedListConfig {
  objectName: string;
  title: string;
  fields: SalesforceField[];
  allowCreate: boolean;
  allowEdit: boolean;
  allowDelete: boolean;
  pageSize: number;
  sortField?: string;
  sortDirection?: 'asc' | 'desc';
  userPermissions?: UserPermissions;
}

export interface EditState {
  recordId: string;
  fieldName: string;
  value: any;
  originalValue: any;
}

export interface ValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}