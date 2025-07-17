import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Apex methods
import getRelatedRecords from '@salesforce/apex/RelatedListInlineEditController.getRelatedRecords';
import saveRecords from '@salesforce/apex/RelatedListInlineEditController.saveRecords';
import deleteRecords from '@salesforce/apex/RelatedListInlineEditController.deleteRecords';
import getFieldMetadata from '@salesforce/apex/RelatedListInlineEditController.getFieldMetadata';
import validateRecords from '@salesforce/apex/RelatedListInlineEditController.validateRecords';
import bulkUpdateRecords from '@salesforce/apex/RelatedListInlineEditController.bulkUpdateRecords';

export default class RelatedListInlineEdit extends LightningElement {
    // Public properties
    @api recordId; // Parent record ID
    @api objectApiName = 'Contact'; // Related object API name
    @api relationshipField = 'AccountId'; // Field that relates to parent
    @api cardTitle = 'Related Records';
    @api fieldsToDisplay = 'Name,Email,Phone,Title'; // Comma-separated field names
    @api pageSize = 10;
    @api allowInlineEdit = true;
    @api allowBulkEdit = true;
    @api allowDelete = true;
    @api showRowNumbers = true;
    @api hideCheckboxColumn = false;
    @api maxRowSelection = 200;
    @api sortedBy = 'Name';
    @api sortedDirection = 'asc';

    // Private properties
    @track tableData = [];
    @track columns = [];
    @track selectedRows = [];
    @track draftValues = [];
    @track availableFields = [];
    @track editableFields = [];
    @track error;
    @track isLoading = true;
    @track showConfigModal = false;
    @track showBulkEditModal = false;
    @track searchTerm = '';
    @track currentPage = 1;
    @track totalRecords = 0;
    @track rowNumberOffset = 0;

    // Pagination properties
    @track pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];

    // Bulk edit properties
    @track bulkEditValues = {};

    // Wire methods
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    @wire(getRelatedRecords, {
        parentId: '$recordId',
        objectApiName: '$objectApiName',
        relationshipField: '$relationshipField',
        fieldsToQuery: '$fieldsToDisplay',
        pageSize: '$pageSize',
        pageNumber: '$currentPage',
        sortField: '$sortedBy',
        sortDirection: '$sortedDirection',
        searchTerm: '$searchTerm'
    })
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        if (result.data) {
            this.processRecordData(result.data);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Error loading records';
            this.tableData = [];
        }
        this.isLoading = false;
    }

    @wire(getFieldMetadata, { objectApiName: '$objectApiName' })
    wiredFieldMetadata(result) {
        if (result.data) {
            this.processFieldMetadata(result.data);
        } else if (result.error) {
            console.error('Error loading field metadata:', result.error);
        }
    }

    // Lifecycle methods
    connectedCallback() {
        this.initializeComponent();
    }

    // Initialization methods
    initializeComponent() {
        this.rowNumberOffset = (this.currentPage - 1) * this.pageSize;
        this.setupColumns();
    }

    processRecordData(data) {
        this.tableData = data.records || [];
        this.totalRecords = data.totalCount || 0;
        this.rowNumberOffset = (this.currentPage - 1) * this.pageSize;
    }

    processFieldMetadata(fieldMetadata) {
        this.availableFields = fieldMetadata.map(field => ({
            ...field,
            visible: this.fieldsToDisplay.includes(field.name)
        }));
        this.setupColumns();
        this.setupEditableFields();
    }

    setupColumns() {
        const fieldNames = this.fieldsToDisplay.split(',').map(f => f.trim());
        this.columns = fieldNames.map(fieldName => {
            const fieldMeta = this.availableFields.find(f => f.name === fieldName);
            if (!fieldMeta) {
                return {
                    label: fieldName,
                    fieldName: fieldName,
                    type: 'text',
                    editable: this.allowInlineEdit
                };
            }

            return this.createColumnDefinition(fieldMeta);
        });

        // Add actions column
        this.columns.push({
            type: 'action',
            typeAttributes: {
                rowActions: this.getRowActions.bind(this)
            }
        });
    }

    createColumnDefinition(fieldMeta) {
        const column = {
            label: fieldMeta.label,
            fieldName: fieldMeta.name,
            type: this.getColumnType(fieldMeta.type),
            editable: this.allowInlineEdit && fieldMeta.editable,
            sortable: fieldMeta.sortable
        };

        // Add type-specific attributes
        switch (fieldMeta.type) {
            case 'CURRENCY':
                column.typeAttributes = {
                    currencyCode: 'USD',
                    minimumFractionDigits: 2
                };
                break;
            case 'PERCENT':
                column.typeAttributes = {
                    minimumFractionDigits: 2
                };
                break;
            case 'DATE':
                column.typeAttributes = {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit'
                };
                break;
            case 'DATETIME':
                column.typeAttributes = {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit'
                };
                break;
            case 'PICKLIST':
                column.typeAttributes = {
                    placeholder: 'Select an option',
                    options: fieldMeta.picklistValues || []
                };
                break;
            case 'REFERENCE':
                column.type = 'url';
                column.typeAttributes = {
                    label: { fieldName: fieldMeta.name + '_Name' },
                    target: '_blank'
                };
                break;
        }

        return column;
    }

    getColumnType(salesforceType) {
        const typeMapping = {
            'STRING': 'text',
            'TEXTAREA': 'text',
            'EMAIL': 'email',
            'PHONE': 'phone',
            'URL': 'url',
            'INTEGER': 'number',
            'DOUBLE': 'number',
            'CURRENCY': 'currency',
            'PERCENT': 'percent',
            'DATE': 'date',
            'DATETIME': 'date',
            'BOOLEAN': 'boolean',
            'PICKLIST': 'text',
            'REFERENCE': 'url'
        };
        return typeMapping[salesforceType] || 'text';
    }

    setupEditableFields() {
        this.editableFields = this.availableFields
            .filter(field => field.editable)
            .map(field => ({
                ...field,
                value: '',
                isText: ['STRING', 'TEXTAREA', 'EMAIL', 'PHONE', 'URL'].includes(field.type),
                isPicklist: field.type === 'PICKLIST',
                isCheckbox: field.type === 'BOOLEAN',
                isDate: ['DATE', 'DATETIME'].includes(field.type),
                options: field.picklistValues || []
            }));
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        
        if (this.allowDelete) {
            actions.push({
                label: 'Delete',
                name: 'delete',
                iconName: 'utility:delete'
            });
        }

        actions.push({
            label: 'View',
            name: 'view',
            iconName: 'utility:preview'
        });

        doneCallback(actions);
    }

    // Event handlers
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'delete':
                this.handleDeleteRecord(row.Id);
                break;
            case 'view':
                this.handleViewRecord(row.Id);
                break;
        }
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.Id);
    }

    handleCellChange(event) {
        this.draftValues = event.detail.draftValues;
    }

    async handleSave(event) {
        const draftValues = event.detail.draftValues;
        this.isLoading = true;

        try {
            // Validate records before saving
            const validationResult = await validateRecords({
                records: draftValues,
                objectApiName: this.objectApiName
            });

            if (!validationResult.isValid) {
                this.showToast('Validation Error', validationResult.errorMessage, 'error');
                return;
            }

            // Save records
            await saveRecords({
                records: draftValues,
                objectApiName: this.objectApiName
            });

            this.showToast('Success', 'Records updated successfully', 'success');
            this.draftValues = [];
            
            // Refresh data
            return refreshApex(this.wiredRecordsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error saving records', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.draftValues = [];
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.currentPage = 1;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.currentPage = 1;
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value);
        this.currentPage = 1;
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (!this.isLastPage) {
            this.currentPage++;
        }
    }

    // Configuration handlers
    handleConfigure() {
        this.showConfigModal = true;
    }

    closeConfigModal() {
        this.showConfigModal = false;
    }

    handleFieldVisibilityChange(event) {
        const fieldName = event.target.dataset.field;
        const isVisible = event.target.checked;
        
        this.availableFields = this.availableFields.map(field => 
            field.name === fieldName ? { ...field, visible: isVisible } : field
        );
    }

    handleShowRowNumbersChange(event) {
        this.showRowNumbers = event.target.checked;
    }

    handleHideCheckboxChange(event) {
        this.hideCheckboxColumn = event.target.checked;
    }

    handleMaxRowSelectionChange(event) {
        this.maxRowSelection = parseInt(event.target.value);
    }

    saveConfiguration() {
        const visibleFields = this.availableFields
            .filter(field => field.visible)
            .map(field => field.name);
        
        this.fieldsToDisplay = visibleFields.join(',');
        this.setupColumns();
        this.closeConfigModal();
        
        this.showToast('Success', 'Configuration saved successfully', 'success');
    }

    // Bulk operations
    handleBulkEdit() {
        if (this.selectedRows.length === 0) {
            this.showToast('Warning', 'Please select records to edit', 'warning');
            return;
        }
        this.showBulkEditModal = true;
    }

    closeBulkEditModal() {
        this.showBulkEditModal = false;
        this.bulkEditValues = {};
    }

    handleBulkFieldChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        
        this.bulkEditValues = {
            ...this.bulkEditValues,
            [fieldName]: value
        };
    }

    async processBulkEdit() {
        if (Object.keys(this.bulkEditValues).length === 0) {
            this.showToast('Warning', 'Please select fields to update', 'warning');
            return;
        }

        this.isLoading = true;

        try {
            await bulkUpdateRecords({
                recordIds: this.selectedRows,
                fieldValues: this.bulkEditValues,
                objectApiName: this.objectApiName
            });

            this.showToast('Success', `${this.selectedRows.length} records updated successfully`, 'success');
            this.closeBulkEditModal();
            this.selectedRows = [];
            
            // Refresh data
            return refreshApex(this.wiredRecordsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error updating records', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleBulkDelete() {
        if (this.selectedRows.length === 0) {
            this.showToast('Warning', 'Please select records to delete', 'warning');
            return;
        }

        if (!confirm(`Are you sure you want to delete ${this.selectedRows.length} record(s)?`)) {
            return;
        }

        this.isLoading = true;

        try {
            await deleteRecords({
                recordIds: this.selectedRows,
                objectApiName: this.objectApiName
            });

            this.showToast('Success', `${this.selectedRows.length} records deleted successfully`, 'success');
            this.selectedRows = [];
            
            // Refresh data
            return refreshApex(this.wiredRecordsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error deleting records', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleDeleteRecord(recordId) {
        if (!confirm('Are you sure you want to delete this record?')) {
            return;
        }

        this.isLoading = true;

        try {
            await deleteRecords({
                recordIds: [recordId],
                objectApiName: this.objectApiName
            });

            this.showToast('Success', 'Record deleted successfully', 'success');
            
            // Refresh data
            return refreshApex(this.wiredRecordsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error deleting record', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleViewRecord(recordId) {
        // Navigate to record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // Export functionality
    handleExport() {
        const csvData = this.convertToCSV(this.tableData);
        const blob = new Blob([csvData], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        
        const link = document.createElement('a');
        link.href = url;
        link.download = `${this.objectApiName}_export.csv`;
        link.click();
        
        window.URL.revokeObjectURL(url);
        this.showToast('Success', 'Data exported successfully', 'success');
    }

    convertToCSV(data) {
        if (!data || data.length === 0) return '';
        
        const headers = this.columns
            .filter(col => col.type !== 'action')
            .map(col => col.label);
        
        const csvRows = [headers.join(',')];
        
        data.forEach(row => {
            const values = this.columns
                .filter(col => col.type !== 'action')
                .map(col => {
                    const value = row[col.fieldName];
                    return value ? `"${value.toString().replace(/"/g, '""')}"` : '';
                });
            csvRows.push(values.join(','));
        });
        
        return csvRows.join('\n');
    }

    // Utility methods
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Computed properties
    get isDisabled() {
        return this.isLoading || this.selectedRows.length === 0;
    }

    get showPagination() {
        return this.totalRecords > this.pageSize;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= Math.ceil(this.totalRecords / this.pageSize);
    }

    get startRecord() {
        return this.totalRecords === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
    }

    get endRecord() {
        const end = this.currentPage * this.pageSize;
        return end > this.totalRecords ? this.totalRecords : end;
    }

    get resizeColumnDisabled() {
        return false;
    }

    get bulkUpdateDisabled() {
        return this.selectedRows.length === 0 || Object.keys(this.bulkEditValues).length === 0;
    }
}