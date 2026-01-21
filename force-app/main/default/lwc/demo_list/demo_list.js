import { LightningElement, track, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import getAllSObjects from '@salesforce/apex/SObjectListControllerssss.getAllSObjects';
import getRecentlyViewedListView from '@salesforce/apex/SObjectListControllerssss.getRecentlyViewedListView';
import updateRecords from '@salesforce/apex/SObjectListControllerssss.updateRecords';
import getRecordsBatch from '@salesforce/apex/SObjectListControllerssss.getRecordsBatch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
export default class Demo_list extends LightningElement {

        @track objectOptions = [];
        @track selectedObject = '';
        @track selectedListView = '';
        @track columns = [];
        @track rows = [];
        @track draftValues = [];
        @track loading = false;
        @track errorMessage = '';
        
    
        wiredListViewResult;
    
        connectedCallback() {
            this.loadObjects();
        }
    
        // Load all objects dynamically
        async loadObjects() {
            this.loading = true;
            try {
                const result = await getAllSObjects();
                this.objectOptions = result.map(obj => ({ label: obj.label, value: obj.apiName }));
            } catch (err) {
                this.showToast('Error', 'Failed to load objects: ' + this.getErrorMessage(err), 'error');
            } finally {
                this.loading = false;
            }
        }
    
        // Handle object selection change
        async handleObjectChange(event) {
            this.selectedObject = event.detail.value;
            this.columns = [];
            this.rows = [];
            this.draftValues = [];
            this.selectedListView = '';
            this.errorMessage = '';
        
            if (!this.selectedObject) return;
        
            this.loading = true;
            try {
                // Check if the object exists in your org
                const objectExists = this.objectOptions.some(obj => obj.value === this.selectedObject);
                if (!objectExists) {
                    this.errorMessage = `The object "${this.selectedObject}" does not exist in this org.`;
                    return;
                }
        
                let listViewApiName = await getRecentlyViewedListView({ objectApiName: this.selectedObject });
        
                if (!listViewApiName) {
                    // Fall back to "All" list view
                    listViewApiName = 'All';
                    this.showToast(
                        'Info',
                        'No Recently Viewed list found. Displaying the "All" list view instead.',
                        'info'
                    );
                }
        
                this.selectedListView = listViewApiName;
            } catch (err) {
                this.errorMessage =
                    err?.body?.message?.includes('resource does not exist')
                        ? `No records or list view available for "${this.selectedObject}".`
                        : 'Error fetching list view: ' + this.getErrorMessage(err);
            } finally {
                this.loading = false;
            }
        }
        
    
        // Wire list view dynamically
        @wire(getListUi, { objectApiName: '$selectedObject', listViewApiName: '$selectedListView' })
        wiredListView(result) {
            this.wiredListViewResult = result;
            const { data, error } = result;
    
            if (data) {
                try {
                    const displayCols = data.info?.displayColumns || [];
    
                    // Build datatable columns dynamically (editable)
                    this.columns = displayCols
                        .filter(c => c.fieldApiName)
                        .map(c => ({
                            label: c.label,
                            fieldName: c.fieldApiName,
                            type: this.getColumnType(c.dataType),
                            editable: this.isColumnEditable(c)
                        }));
    
                    // Map rows
                    this.rows = (data.records?.records || []).map(rec => {
                        const row = { Id: rec.id };
                        displayCols.forEach(c => {
                            if (!c.fieldApiName) return;
                            row[c.fieldApiName] = rec.fields?.[c.fieldApiName]?.value ?? null;
                        });
                        return row;
                    });
    
                    this.errorMessage = '';
                } catch (e) {
                    console.error('Error mapping list view data:', e);
                    this.rows = [];
                    this.columns = [];
                    this.errorMessage = 'Failed to map list view data.';
                }
            } else if (error) {
                console.error('Error loading list view:', error);
                this.rows = [];
                this.columns = [];
                this.errorMessage = ' ' + this.getErrorMessage(error);
            }
        }
    
        // Determine editable columns
        isColumnEditable(colInfo) {
            if (typeof colInfo.editable === 'boolean') return colInfo.editable;
    
            const name = (colInfo.fieldApiName || '').toLowerCase();
            const nonEditablePatterns = [
                '^id$', 'createddate', 'lastmodifieddate', 'systemmodstamp', 'createdbyid',
                'lastmodifiedbyid', 'isdeleted', 'ownerid', '^recordtypeid$', '^currencyiso$', 'latitude', 'longitude'
            ];
            if (nonEditablePatterns.some(p => new RegExp(p).test(name))) return false;
    
            const nonEditableTypes = ['reference', 'location', 'base64', 'textarea', 'json'];
            if (colInfo.dataType && nonEditableTypes.includes(colInfo.dataType.toLowerCase())) return false;
    
            return true;
        }
    
        // Map Salesforce field type to datatable type
        getColumnType(apiType) {
            if (!apiType) return 'text';
            switch (apiType.toLowerCase()) {
                case 'phone': return 'phone';
                case 'email': return 'email';
                case 'date':
                case 'datetime': return 'date';
                case 'currency': return 'currency';
                case 'double':
                case 'integer':
                case 'percent': return 'number';
                case 'boolean': return 'boolean';
                case 'url': return 'url';
                case 'reference': return 'text';
                default: return 'text';
            }
        }
    
        // Inline save handler
        async handleInlineSave(event) {
            const updatedFields = event.detail.draftValues;
            if (!updatedFields || updatedFields.length === 0) return;
    
            this.loading = true;
            try {
                const payload = updatedFields.map(dv => ({
                    sobjectType: this.selectedObject,
                    fields: { ...dv }
                }));
    
                await updateRecords({ updates: payload });
                this.draftValues = [];
                this.refreshList();
                this.showToast('Success', `${updatedFields.length} record(s) updated successfully`, 'success');
            } catch (err) {
                console.error(err);
                this.showToast('Error', 'Failed to update records: ' + this.getErrorMessage(err), 'error');
            } finally {
                this.loading = false;
            }
        }
    
        refreshList() {
            if (this.wiredListViewResult) refreshApex(this.wiredListViewResult);
        }
    
        showToast(title, message, variant = 'info') {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        }
    
        getErrorMessage(err) {
            return err?.body?.message || err?.message || JSON.stringify(err);
        }
    
        get showNoRecordsMessage() {
            return !this.loading && (!this.rows || this.rows.length === 0);
        }
    
        get showDatatable() {
            return this.columns && this.columns.length > 0;
        }
}