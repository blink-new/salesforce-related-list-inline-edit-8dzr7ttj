import React, { useState, useCallback } from 'react';
import { RelatedListInlineEdit } from './components/RelatedListInlineEdit';
import { SalesforceRecord, RelatedListConfig, SalesforceField } from './types/salesforce';
import { Button } from './components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from './components/ui/card';
import { Badge } from './components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './components/ui/tabs';
import { Settings, Database, Users, Zap } from 'lucide-react';
import { toast, Toaster } from 'sonner';

// Sample data for demonstration
const sampleFields: SalesforceField[] = [
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
    required: true,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 250
  },
  {
    id: 'phone',
    name: 'phone',
    label: 'Phone',
    type: 'phone',
    required: false,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 150
  },
  {
    id: 'status',
    name: 'status',
    label: 'Status',
    type: 'picklist',
    required: true,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 120,
    picklistValues: ['Active', 'Inactive', 'Pending', 'Suspended']
  },
  {
    id: 'priority',
    name: 'priority',
    label: 'Priority',
    type: 'picklist',
    required: false,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 100,
    picklistValues: ['High', 'Medium', 'Low']
  },
  {
    id: 'amount',
    name: 'amount',
    label: 'Amount',
    type: 'currency',
    required: false,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 120
  },
  {
    id: 'closeDate',
    name: 'closeDate',
    label: 'Close Date',
    type: 'date',
    required: false,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 140
  },
  {
    id: 'isActive',
    name: 'isActive',
    label: 'Active',
    type: 'checkbox',
    required: false,
    editable: true,
    visible: true,
    sortable: true,
    filterable: true,
    width: 80
  },
  {
    id: 'description',
    name: 'description',
    label: 'Description',
    type: 'textarea',
    required: false,
    editable: true,
    visible: true,
    sortable: false,
    filterable: true,
    width: 200
  }
];

const sampleRecords: SalesforceRecord[] = [
  {
    id: '001',
    name: 'Acme Corporation',
    email: 'contact@acme.com',
    phone: '+1 (555) 123-4567',
    status: 'Active',
    priority: 'High',
    amount: 150000,
    closeDate: '2024-03-15',
    isActive: true,
    description: 'Major enterprise client with multiple locations'
  },
  {
    id: '002',
    name: 'TechStart Inc.',
    email: 'hello@techstart.io',
    phone: '+1 (555) 987-6543',
    status: 'Pending',
    priority: 'Medium',
    amount: 75000,
    closeDate: '2024-02-28',
    isActive: true,
    description: 'Innovative startup in the AI space'
  },
  {
    id: '003',
    name: 'Global Solutions Ltd.',
    email: 'info@globalsolutions.com',
    phone: '+1 (555) 456-7890',
    status: 'Active',
    priority: 'Low',
    amount: 250000,
    closeDate: '2024-04-10',
    isActive: false,
    description: 'International consulting firm'
  },
  {
    id: '004',
    name: 'Innovation Labs',
    email: 'team@innovationlabs.com',
    phone: '+1 (555) 321-0987',
    status: 'Inactive',
    priority: 'High',
    amount: 50000,
    closeDate: '2024-01-20',
    isActive: false,
    description: 'R&D focused technology company'
  },
  {
    id: '005',
    name: 'Digital Dynamics',
    email: 'contact@digitaldynamics.net',
    phone: '+1 (555) 654-3210',
    status: 'Active',
    priority: 'Medium',
    amount: 125000,
    closeDate: '2024-03-05',
    isActive: true,
    description: 'Digital transformation specialists'
  }
];

const opportunityConfig: RelatedListConfig = {
  objectName: 'Opportunity',
  title: 'Opportunities',
  fields: sampleFields,
  allowCreate: true,
  allowEdit: true,
  allowDelete: true,
  pageSize: 10,
  sortField: 'name',
  sortDirection: 'asc'
};

const contactConfig: RelatedListConfig = {
  objectName: 'Contact',
  title: 'Contacts',
  fields: sampleFields.filter(f => ['name', 'email', 'phone', 'status', 'isActive'].includes(f.name)),
  allowCreate: true,
  allowEdit: true,
  allowDelete: true,
  pageSize: 10,
  sortField: 'name',
  sortDirection: 'asc'
};

function App() {
  const [opportunityRecords, setOpportunityRecords] = useState<SalesforceRecord[]>(sampleRecords);
  const [contactRecords, setContactRecords] = useState<SalesforceRecord[]>(
    sampleRecords.map(record => ({
      id: record.id,
      name: record.name,
      email: record.email,
      phone: record.phone,
      status: record.status,
      isActive: record.isActive
    }))
  );
  const [loading, setLoading] = useState(false);

  // Simulate API calls
  const handleSave = useCallback(async (records: SalesforceRecord[], type: 'opportunity' | 'contact') => {
    setLoading(true);
    
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    try {
      if (type === 'opportunity') {
        setOpportunityRecords(prev => 
          prev.map(existing => {
            const updated = records.find(r => r.id === existing.id);
            return updated ? { ...updated, isDirty: false } : existing;
          })
        );
      } else {
        setContactRecords(prev => 
          prev.map(existing => {
            const updated = records.find(r => r.id === existing.id);
            return updated ? { ...updated, isDirty: false } : existing;
          })
        );
      }
      
      toast.success(`Successfully updated ${records.length} record(s)`);
    } catch (error) {
      toast.error('Failed to save records');
      throw error;
    } finally {
      setLoading(false);
    }
  }, []);

  const handleDelete = useCallback(async (recordIds: string[], type: 'opportunity' | 'contact') => {
    setLoading(true);
    
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 800));
    
    try {
      if (type === 'opportunity') {
        setOpportunityRecords(prev => prev.filter(record => !recordIds.includes(record.id)));
      } else {
        setContactRecords(prev => prev.filter(record => !recordIds.includes(record.id)));
      }
      
      toast.success(`Successfully deleted ${recordIds.length} record(s)`);
    } catch (error) {
      toast.error('Failed to delete records');
      throw error;
    } finally {
      setLoading(false);
    }
  }, []);

  const handleRefresh = useCallback(async (type: 'opportunity' | 'contact') => {
    setLoading(true);
    
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1200));
    
    try {
      // In a real app, this would fetch fresh data from the server
      toast.success('Data refreshed successfully');
    } catch (error) {
      toast.error('Failed to refresh data');
    } finally {
      setLoading(false);
    }
  }, []);

  return (
    <div className="min-h-screen bg-[#FAFBFC]">
      <Toaster position="top-right" />
      
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 bg-[#0176D3] rounded-lg flex items-center justify-center">
                  <Database className="h-5 w-5 text-white" />
                </div>
                <h1 className="text-2xl font-semibold text-gray-900">
                  Salesforce Related List
                </h1>
              </div>
              <Badge variant="secondary" className="bg-blue-50 text-blue-700">
                Inline Edit Component
              </Badge>
            </div>
            
            <div className="flex items-center space-x-2">
              <Badge variant="outline" className="text-green-600 border-green-200">
                <Zap className="h-3 w-3 mr-1" />
                Live Demo
              </Badge>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* Feature Overview */}
        <div className="mb-8">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center text-[#0176D3]">
                <Settings className="h-5 w-5 mr-2" />
                Component Features
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="text-center p-4 bg-blue-50 rounded-lg">
                  <div className="text-2xl font-bold text-[#0176D3]">9+</div>
                  <div className="text-sm text-gray-600">Field Types</div>
                </div>
                <div className="text-center p-4 bg-green-50 rounded-lg">
                  <div className="text-2xl font-bold text-green-600">✓</div>
                  <div className="text-sm text-gray-600">Inline Editing</div>
                </div>
                <div className="text-center p-4 bg-purple-50 rounded-lg">
                  <div className="text-2xl font-bold text-purple-600">⚡</div>
                  <div className="text-sm text-gray-600">Bulk Operations</div>
                </div>
                <div className="text-center p-4 bg-orange-50 rounded-lg">
                  <div className="text-2xl font-bold text-orange-600">🎯</div>
                  <div className="text-sm text-gray-600">Validation</div>
                </div>
              </div>
              
              <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div className="flex items-center text-gray-600">
                  <div className="w-2 h-2 bg-blue-500 rounded-full mr-2"></div>
                  Click-to-edit cells
                </div>
                <div className="flex items-center text-gray-600">
                  <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                  Multi-select actions
                </div>
                <div className="flex items-center text-gray-600">
                  <div className="w-2 h-2 bg-purple-500 rounded-full mr-2"></div>
                  Field validation
                </div>
                <div className="flex items-center text-gray-600">
                  <div className="w-2 h-2 bg-orange-500 rounded-full mr-2"></div>
                  Responsive design
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Demo Tabs */}
        <Tabs defaultValue="opportunities" className="space-y-6">
          <TabsList className="grid w-full grid-cols-2 max-w-md">
            <TabsTrigger value="opportunities" className="flex items-center">
              <Database className="h-4 w-4 mr-2" />
              Opportunities
            </TabsTrigger>
            <TabsTrigger value="contacts" className="flex items-center">
              <Users className="h-4 w-4 mr-2" />
              Contacts
            </TabsTrigger>
          </TabsList>

          <TabsContent value="opportunities" className="space-y-4">
            <div className="bg-white p-4 rounded-lg border border-gray-200">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Opportunities Demo
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                Try clicking on any cell to edit inline. Select multiple records for bulk operations.
                Supports text, email, phone, currency, date, checkbox, picklist, and textarea fields.
              </p>
              
              <RelatedListInlineEdit
                config={opportunityConfig}
                records={opportunityRecords}
                onSave={(records) => handleSave(records, 'opportunity')}
                onDelete={(recordIds) => handleDelete(recordIds, 'opportunity')}
                onRefresh={() => handleRefresh('opportunity')}
                loading={loading}
              />
            </div>
          </TabsContent>

          <TabsContent value="contacts" className="space-y-4">
            <div className="bg-white p-4 rounded-lg border border-gray-200">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Contacts Demo
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                A simplified view showing core contact fields. Demonstrates the component's 
                flexibility with different field configurations.
              </p>
              
              <RelatedListInlineEdit
                config={contactConfig}
                records={contactRecords}
                onSave={(records) => handleSave(records, 'contact')}
                onDelete={(recordIds) => handleDelete(recordIds, 'contact')}
                onRefresh={() => handleRefresh('contact')}
                loading={loading}
              />
            </div>
          </TabsContent>
        </Tabs>

        {/* Instructions */}
        <Card className="mt-8">
          <CardHeader>
            <CardTitle className="text-[#0176D3]">How to Use</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 className="font-medium text-gray-900 mb-2">Inline Editing</h4>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li>• Click any editable cell to start editing</li>
                  <li>• Use ✓ to save or ✗ to cancel changes</li>
                  <li>• Different field types have appropriate editors</li>
                  <li>• Changes are highlighted with yellow background</li>
                </ul>
              </div>
              
              <div>
                <h4 className="font-medium text-gray-900 mb-2">Bulk Operations</h4>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li>• Select multiple records using checkboxes</li>
                  <li>• Use "Bulk Edit" to update selected records</li>
                  <li>• Use "Delete" to remove selected records</li>
                  <li>• Selection count is shown in the header</li>
                </ul>
              </div>
            </div>
            
            <div className="pt-4 border-t">
              <h4 className="font-medium text-gray-900 mb-2">Supported Field Types</h4>
              <div className="flex flex-wrap gap-2">
                {['Text', 'Email', 'Phone', 'Number', 'Currency', 'Date', 'DateTime', 'Checkbox', 'Picklist', 'Textarea'].map((type) => (
                  <Badge key={type} variant="outline" className="text-xs">
                    {type}
                  </Badge>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}

export default App;