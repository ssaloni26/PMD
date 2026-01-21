import { refreshApex } from '@salesforce/apex';
import getAllSObjects from '@salesforce/apex/SObjectListController.getAllSObjects';
import getFieldsForObject from '@salesforce/apex/SObjectListController.getFieldsForObject';
import getRecordsWithSelectedFields from '@salesforce/apex/SObjectListController.getRecordsWithSelectedFields';
import updateRecords from '@salesforce/apex/SObjectListController.updateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, track, wire } from 'lwc';

export default class DynamicObjectList extends LightningElement {
    @track objectOptions = [];
    @track selectedObject = '';
    @track fieldOptions = [];
    @track selectedFields = [];
    @track columns = [];
    @track rows = [];
    @track draftValues = [];
    @track loading = false;
    @track fieldsModalVisible = false;
    @track enableInfiniteScroll = false;

    allRecords = [];
    rowLimit = 20;
    currentOffset = 0;
    wiredRecordsResult;


    @wire(getAllSObjects)
    wiredObjects({ data, error }) {
        if (data) this.objectOptions = data.map(o => ({ label: o.label, value: o.apiName }));
        if (error) this.showToast('Error', this.getErrorMessage(error), 'error');
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedFields = [];
        this.resetData();

        if (!this.selectedObject) return;

        this.loading = true;
        getFieldsForObject({ objectApiName: this.selectedObject })
            .then(fields => { this.fieldOptions = fields; this.fieldsModalVisible = true; })
            .catch(err => this.showToast('Error', this.getErrorMessage(err), 'error'))
            .finally(() => this.loading = false);
    }

    handleFieldSelectionChange(event) { this.selectedFields = event.detail.value; }
    handleCancel() { this.fieldsModalVisible = false; this.selectedFields = []; }

    handleLoad() {
        if (!this.selectedFields.length) return this.showToast('Warning', 'Select at least one field.', 'warning');

        this.columns = [
            { label: 'Id', fieldName: 'Id', type: 'text', editable: false },
            ...this.selectedFields.map(fName => {
                const field = this.fieldOptions.find(f => f.value === fName);
                return { label: field.label, fieldName: field.value, type: 'text', editable: field.updateable === 'true' };
            })
        ];

        this.fieldsModalVisible = false;
        if (this.wiredRecordsResult) {
            this.loading = true;
            refreshApex(this.wiredRecordsResult)
                .catch(err => this.handleNoRecords(err))
                .finally(() => this.loading = false);
        }
    }

    @wire(getRecordsWithSelectedFields, { objectApiName: '$selectedObject', fieldNames: '$selectedFields', limitSize: 2000 })
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        const { data, error } = result;
        this.loading = true;

        if (data) {
            this.allRecords = data.map(r => ({ ...r })); 
            console.log('Total records:', this.allRecords.length);
            this.currentOffset = 0;
            this.rows = [];
        
            if (this.allRecords.length) {
                this.enableInfiniteScroll = true;
                this.loadNextBatch();
            } else {
                this.showNoRecords();
            }
        }
        
        if (error) {
            this.allRecords = [];
            this.rows = [];
            this.enableInfiniteScroll = false;
            const msg = this.getErrorMessage(error);
            if (!msg.includes('No such column') && !msg.includes('object not allowed')) this.showToast('Error', msg, 'error');
        }

        this.loading = false;
    }

    loadNextBatch() {
        if (!this.allRecords || this.currentOffset >= this.allRecords.length) { this.enableInfiniteScroll = false; return; }
        const nextBatch = this.allRecords.slice(this.currentOffset, this.currentOffset + this.rowLimit);
        this.rows = [...this.rows, ...nextBatch];
        this.currentOffset += nextBatch.length;
        this.enableInfiniteScroll = this.currentOffset < this.allRecords.length;
    }

    handleLoadMore(event) {
        if (this.isLoadingMore || !this.enableInfiniteScroll) return;
    
        this.isLoadingMore = true;
        event.target.isLoading = true;
    
        const nextBatch = this.allRecords.slice(this.currentOffset, this.currentOffset + this.rowLimit);
        this.rows = [...this.rows, ...nextBatch];
        this.currentOffset += nextBatch.length;
    
        if (this.currentOffset >= this.allRecords.length) {
            this.enableInfiniteScroll = false;
            event.target.enableInfiniteLoading = false;
        }
    
        this.isLoadingMore = false;
        event.target.isLoading = false;
    }
    


    handleInlineSave(event) {
        const updates = event.detail.draftValues;
        if (!updates?.length) return;
    
        this.loading = true;
   
        const payload = updates.map(dv => {
            let sobj = { sobjectType: this.selectedObject };
          
            Object.keys(dv).forEach(f => {
                sobj[f] = dv[f];
            });
            return sobj;
        });
    
        updateRecords({ updateRecords: payload })
            .then(() => {
                this.showToast('Success', `${updates.length} record(s) updated.`, 'success');
                this.draftValues = [];
                if (this.wiredRecordsResult) refreshApex(this.wiredRecordsResult);
            })
            .catch(err => this.showToast('Error', this.getErrorMessage(err), 'error'))
            .finally(() => this.loading = false);
    }

    resetData() { this.rows = []; this.columns = []; this.allRecords = []; this.currentOffset = 0; this.enableInfiniteScroll = false; this.draftValues = []; }

    handleNoRecords(err) {
        const msg = this.getErrorMessage(err);
        if (msg.includes('No such column') || msg.includes('object not allowed')) this.showNoRecords();
        else this.showToast('Error', msg, 'error');
    }

    showNoRecords() {
        this.rows = this.selectedFields.length ? [this.selectedFields.reduce((acc, f) => ({ ...acc, [f]: 'No Records' }), { Id: '—' })] : [];
        this.enableInfiniteScroll = false;
    }

    getErrorMessage(err) { return err?.body?.message || err?.message || JSON.stringify(err); }
    showToast(title, message, variant = 'info') { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    get showDatatable() { return this.rows.length > 0 && this.columns.length > 0; }
    openFieldsModal() { this.fieldsModalVisible = true; }
}