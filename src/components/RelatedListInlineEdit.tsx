import React, { useState, useCallback, useMemo } from 'react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Checkbox } from './ui/checkbox';
import { Badge } from './ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Separator } from './ui/separator';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from './ui/tooltip';
import { 
  Edit3, 
  Save, 
  X, 
  Plus, 
  Trash2, 
  MoreHorizontal, 
  Check, 
  AlertCircle,
  Users,
  Settings,
  Download,
  Upload,
  RefreshCw
} from 'lucide-react';
import { SalesforceField, SalesforceRecord, RelatedListConfig, EditState } from '../types/salesforce';

interface RelatedListInlineEditProps {
  config: RelatedListConfig;
  records: SalesforceRecord[];
  onSave: (records: SalesforceRecord[]) => Promise<void>;
  onDelete: (recordIds: string[]) => Promise<void>;
  onRefresh: () => Promise<void>;
  loading?: boolean;
}

interface BulkEditState {
  isOpen: boolean;
  selectedRecords: string[];
  field: string;
  value: any;
}

export const RelatedListInlineEdit: React.FC<RelatedListInlineEditProps> = ({
  config,
  records,
  onSave,
  onDelete,
  onRefresh,
  loading = false
}) => {
  const [editStates, setEditStates] = useState<Record<string, EditState>>({});
  const [selectedRecords, setSelectedRecords] = useState<Set<string>>(new Set());
  const [bulkEdit, setBulkEdit] = useState<BulkEditState>({
    isOpen: false,
    selectedRecords: [],
    field: '',
    value: ''
  });
  const [isProcessing, setIsProcessing] = useState(false);

  // Get visible fields
  const visibleFields = useMemo(() => 
    config.fields.filter(field => field.visible),
    [config.fields]
  );

  // Handle cell edit start
  const handleEditStart = useCallback((recordId: string, fieldName: string, currentValue: any) => {
    const editKey = `${recordId}-${fieldName}`;
    setEditStates(prev => ({
      ...prev,
      [editKey]: {
        recordId,
        fieldName,
        value: currentValue,
        originalValue: currentValue
      }
    }));
  }, []);

  // Handle cell value change
  const handleEditChange = useCallback((recordId: string, fieldName: string, newValue: any) => {
    const editKey = `${recordId}-${fieldName}`;
    setEditStates(prev => ({
      ...prev,
      [editKey]: {
        ...prev[editKey],
        value: newValue
      }
    }));
  }, []);

  // Handle cell edit save
  const handleEditSave = useCallback(async (recordId: string, fieldName: string) => {
    const editKey = `${recordId}-${fieldName}`;
    const editState = editStates[editKey];
    
    if (!editState) return;

    try {
      setIsProcessing(true);
      const updatedRecord = {
        ...records.find(r => r.id === recordId)!,
        [fieldName]: editState.value,
        isDirty: true
      };
      
      await onSave([updatedRecord]);
      
      // Remove edit state
      setEditStates(prev => {
        const newState = { ...prev };
        delete newState[editKey];
        return newState;
      });
    } catch (error) {
      console.error('Save failed:', error);
    } finally {
      setIsProcessing(false);
    }
  }, [editStates, records, onSave]);

  // Handle cell edit cancel
  const handleEditCancel = useCallback((recordId: string, fieldName: string) => {
    const editKey = `${recordId}-${fieldName}`;
    setEditStates(prev => {
      const newState = { ...prev };
      delete newState[editKey];
      return newState;
    });
  }, []);

  // Handle record selection
  const handleRecordSelect = useCallback((recordId: string, checked: boolean) => {
    setSelectedRecords(prev => {
      const newSet = new Set(prev);
      if (checked) {
        newSet.add(recordId);
      } else {
        newSet.delete(recordId);
      }
      return newSet;
    });
  }, []);

  // Handle select all
  const handleSelectAll = useCallback((checked: boolean) => {
    if (checked) {
      setSelectedRecords(new Set(records.map(r => r.id)));
    } else {
      setSelectedRecords(new Set());
    }
  }, [records]);

  // Open bulk edit dialog
  const handleBulkEditOpen = useCallback(() => {
    setBulkEdit({
      isOpen: true,
      selectedRecords: Array.from(selectedRecords),
      field: '',
      value: ''
    });
  }, [selectedRecords]);

  // Handle bulk edit apply
  const handleBulkEditApply = useCallback(async () => {
    if (!bulkEdit.field || bulkEdit.selectedRecords.length === 0) return;

    try {
      setIsProcessing(true);
      
      const updatedRecords = bulkEdit.selectedRecords.map(recordId => {
        const record = records.find(r => r.id === recordId)!;
        return {
          ...record,
          [bulkEdit.field]: bulkEdit.value,
          isDirty: true
        };
      });

      await onSave(updatedRecords);
      
      setBulkEdit({ isOpen: false, selectedRecords: [], field: '', value: '' });
      setSelectedRecords(new Set());
    } catch (error) {
      console.error('Bulk update failed:', error);
    } finally {
      setIsProcessing(false);
    }
  }, [bulkEdit, records, onSave]);

  // Handle bulk delete
  const handleBulkDelete = useCallback(async () => {
    if (selectedRecords.size === 0) return;
    
    try {
      setIsProcessing(true);
      await onDelete(Array.from(selectedRecords));
      setSelectedRecords(new Set());
    } catch (error) {
      console.error('Bulk delete failed:', error);
    } finally {
      setIsProcessing(false);
    }
  }, [selectedRecords, onDelete]);

  // Render field editor
  const renderFieldEditor = (field: SalesforceField, value: any, onChange: (value: any) => void) => {
    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'url':
        return (
          <Input
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            placeholder={field.label}
            className="h-8 text-sm"
          />
        );
      
      case 'textarea':
        return (
          <Textarea
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            placeholder={field.label}
            className="min-h-[60px] text-sm"
          />
        );
      
      case 'number':
      case 'currency':
        return (
          <Input
            type="number"
            value={value || ''}
            onChange={(e) => onChange(parseFloat(e.target.value) || 0)}
            placeholder={field.label}
            className="h-8 text-sm"
          />
        );
      
      case 'date':
        return (
          <Input
            type="date"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            className="h-8 text-sm"
          />
        );
      
      case 'datetime':
        return (
          <Input
            type="datetime-local"
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            className="h-8 text-sm"
          />
        );
      
      case 'checkbox':
        return (
          <Checkbox
            checked={value || false}
            onCheckedChange={onChange}
          />
        );
      
      case 'picklist':
        return (
          <Select value={value || ''} onValueChange={onChange}>
            <SelectTrigger className="h-8 text-sm">
              <SelectValue placeholder={`Select ${field.label}`} />
            </SelectTrigger>
            <SelectContent>
              {field.picklistValues?.map((option) => (
                <SelectItem key={option} value={option}>
                  {option}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        );
      
      default:
        return (
          <Input
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            placeholder={field.label}
            className="h-8 text-sm"
          />
        );
    }
  };

  // Render cell content
  const renderCellContent = (record: SalesforceRecord, field: SalesforceField) => {
    const editKey = `${record.id}-${field.name}`;
    const editState = editStates[editKey];
    const value = record[field.name];

    if (editState) {
      return (
        <div className="flex items-center gap-1">
          <div className="flex-1">
            {renderFieldEditor(field, editState.value, (newValue) => 
              handleEditChange(record.id, field.name, newValue)
            )}
          </div>
          <div className="flex gap-1">
            <Button
              size="sm"
              variant="ghost"
              className="h-6 w-6 p-0 text-green-600 hover:text-green-700"
              onClick={() => handleEditSave(record.id, field.name)}
              disabled={isProcessing}
            >
              <Check className="h-3 w-3" />
            </Button>
            <Button
              size="sm"
              variant="ghost"
              className="h-6 w-6 p-0 text-red-600 hover:text-red-700"
              onClick={() => handleEditCancel(record.id, field.name)}
            >
              <X className="h-3 w-3" />
            </Button>
          </div>
        </div>
      );
    }

    return (
      <div 
        className="group flex items-center justify-between cursor-pointer hover:bg-gray-50 p-1 rounded"
        onClick={() => field.editable && handleEditStart(record.id, field.name, value)}
      >
        <span className="text-sm">
          {field.type === 'checkbox' ? (
            <Checkbox checked={value || false} disabled />
          ) : field.type === 'currency' ? (
            `$${(value || 0).toLocaleString()}`
          ) : (
            value || '-'
          )}
        </span>
        {field.editable && (
          <Edit3 className="h-3 w-3 opacity-0 group-hover:opacity-100 text-gray-400" />
        )}
      </div>
    );
  };

  const allSelected = selectedRecords.size === records.length && records.length > 0;
  const someSelected = selectedRecords.size > 0 && selectedRecords.size < records.length;

  return (
    <TooltipProvider>
      <Card className="w-full">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-lg font-semibold text-[#0176D3]">
              {config.title}
            </CardTitle>
            <div className="flex items-center gap-2">
              {selectedRecords.size > 0 && (
                <>
                  <Badge variant="secondary" className="bg-blue-50 text-blue-700">
                    {selectedRecords.size} selected
                  </Badge>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={handleBulkEditOpen}
                    className="text-[#0176D3] border-[#0176D3] hover:bg-blue-50"
                  >
                    <Users className="h-4 w-4 mr-1" />
                    Bulk Edit
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={handleBulkDelete}
                    className="text-red-600 border-red-200 hover:bg-red-50"
                    disabled={isProcessing}
                  >
                    <Trash2 className="h-4 w-4 mr-1" />
                    Delete
                  </Button>
                </>
              )}
              <Button
                size="sm"
                variant="outline"
                onClick={onRefresh}
                disabled={loading}
              >
                <RefreshCw className={`h-4 w-4 mr-1 ${loading ? 'animate-spin' : ''}`} />
                Refresh
              </Button>
            </div>
          </div>
        </CardHeader>
        
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="w-12 p-3 text-left">
                    <Checkbox
                      checked={allSelected}
                      ref={(el) => {
                        if (el) el.indeterminate = someSelected;
                      }}
                      onCheckedChange={handleSelectAll}
                    />
                  </th>
                  {visibleFields.map((field) => (
                    <th
                      key={field.id}
                      className="p-3 text-left text-sm font-medium text-gray-700"
                      style={{ width: field.width }}
                    >
                      {field.label}
                      {field.required && <span className="text-red-500 ml-1">*</span>}
                    </th>
                  ))}
                  <th className="w-12 p-3"></th>
                </tr>
              </thead>
              <tbody>
                {records.map((record, index) => (
                  <tr
                    key={record.id}
                    className={`border-b hover:bg-gray-50 ${
                      selectedRecords.has(record.id) ? 'bg-blue-50' : ''
                    } ${record.isDirty ? 'bg-yellow-50' : ''}`}
                  >
                    <td className="p-3">
                      <Checkbox
                        checked={selectedRecords.has(record.id)}
                        onCheckedChange={(checked) => 
                          handleRecordSelect(record.id, checked as boolean)
                        }
                      />
                    </td>
                    {visibleFields.map((field) => (
                      <td key={field.id} className="p-3">
                        {renderCellContent(record, field)}
                      </td>
                    ))}
                    <td className="p-3">
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-6 w-6 p-0"
                      >
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          {records.length === 0 && (
            <div className="text-center py-12 text-gray-500">
              <Users className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No records found</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Bulk Edit Dialog */}
      <Dialog open={bulkEdit.isOpen} onOpenChange={(open) => 
        setBulkEdit(prev => ({ ...prev, isOpen: open }))
      }>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-[#0176D3]">
              Bulk Edit Records
            </DialogTitle>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <Label className="text-sm font-medium">
                Selected Records: {bulkEdit.selectedRecords.length}
              </Label>
              <p className="text-xs text-gray-500 mt-1">
                Changes will be applied to all selected records
              </p>
            </div>
            
            <Separator />
            
            <div className="space-y-3">
              <div>
                <Label htmlFor="bulk-field" className="text-sm font-medium">
                  Field to Update
                </Label>
                <Select
                  value={bulkEdit.field}
                  onValueChange={(value) => 
                    setBulkEdit(prev => ({ ...prev, field: value, value: '' }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select a field" />
                  </SelectTrigger>
                  <SelectContent>
                    {visibleFields
                      .filter(field => field.editable)
                      .map((field) => (
                        <SelectItem key={field.id} value={field.name}>
                          {field.label}
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </div>
              
              {bulkEdit.field && (
                <div>
                  <Label htmlFor="bulk-value" className="text-sm font-medium">
                    New Value
                  </Label>
                  <div className="mt-1">
                    {renderFieldEditor(
                      visibleFields.find(f => f.name === bulkEdit.field)!,
                      bulkEdit.value,
                      (value) => setBulkEdit(prev => ({ ...prev, value }))
                    )}
                  </div>
                </div>
              )}
            </div>
            
            <div className="flex justify-end gap-2 pt-4">
              <Button
                variant="outline"
                onClick={() => setBulkEdit(prev => ({ ...prev, isOpen: false }))}
              >
                Cancel
              </Button>
              <Button
                onClick={handleBulkEditApply}
                disabled={!bulkEdit.field || isProcessing}
                className="bg-[#0176D3] hover:bg-blue-700"
              >
                {isProcessing ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Updating...
                  </>
                ) : (
                  <>
                    <Check className="h-4 w-4 mr-2" />
                    Apply Changes
                  </>
                )}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </TooltipProvider>
  );
};