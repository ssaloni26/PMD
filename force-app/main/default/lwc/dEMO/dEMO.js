import { refreshApex } from '@salesforce/apex';
import getAllSObjects from '@salesforce/apex/SObjectListController.getAllSObjects';
import getFieldsForObject from '@salesforce/apex/SObjectListController.getFieldsForObject';
import getRecordsWithSelectedFields from '@salesforce/apex/SObjectListController.getRecordsWithSelectedFields';
import updateRecords from '@salesforce/apex/SObjectListController.updateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, track, wire } from 'lwc';

export default class Demo extends LightningElement {
    @track objectOptions = [];
    @track selectedObject = '';
    @track fieldOptions = [];
    @track selectedFields = [];
    @track columns = [];
    @track rows = [];
    @track draftValues = [];
    @track loading = false;
    @track errorMessage = '';
    @track isLoadingMore = false;
    @track enableInfiniteScroll = false;

    allRecords = [];
    rowLimit = 20;
    currentOffset = 0;

    wiredObjectsResult;
    wiredRecordsResult;

    @wire(getAllSObjects)
    wiredObjects(result) {
        this.wiredObjectsResult = result;
        if (result.data) {
            this.objectOptions = result.data.map(obj => ({ label: obj.label, value: obj.apiName }));
        } else if (result.error) {
            this.showToast('Error', this.getErrorMessage(result.error), 'error');
        }
    }

    async handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedFields = []; // Reset selected fields on object change
        this.resetData();

        if (!this.selectedObject) return;

        this.loading = true;
        try {
            const fields = await getFieldsForObject({ objectApiName: this.selectedObject });
            this.fieldOptions = fields.map(f => ({ label: f, value: f }));
        } catch (err) {
            this.showToast('Error', this.getErrorMessage(err), 'error');
        } finally {
            this.loading = false;
        }
    }

    async handleFieldSelectionChange(event) {
        this.selectedFields = event.detail.value;
        this.resetData();

        if (this.selectedFields.length === 0) return;

        // Prepare columns even if no records yet
        this.columns = [
            { label: 'Id', fieldName: 'Id', type: 'text', editable: false },
            ...this.selectedFields.map(f => ({
                label: f,
                fieldName: f,
                type: 'text',
                editable: true
            }))
        ];

        // Refresh records if previously wired
        if (this.wiredRecordsResult) {
            this.loading = true;
            try {
                await refreshApex(this.wiredRecordsResult);
            } catch (err) {
                const msg = this.getErrorMessage(err);
                // If error is metadata issue, show "No Records" in table
                if (msg.includes('No such column') || msg.includes('object not allowed')) {
                    this.rows = [
                        this.selectedFields.reduce((acc, f) => ({ ...acc, [f]: 'No Records' }), { Id: '—' })
                    ];
                } else {
                    this.showToast('Error', msg, 'error');
                }
            } finally {
                this.loading = false;
            }
        }
    }

    @wire(getRecordsWithSelectedFields, {
        objectApiName: '$selectedObject',
        fieldNames: '$selectedFields',
        limitSize: 2000
    })
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        this.loading = true;

        if (result.data) {
            this.allRecords = result.data.map(r => ({ ...r }));
            this.currentOffset = 0;
            this.rows = [];

            if (this.allRecords.length === 0) {
                // Only show "No Records" if there is no data
                if (this.selectedFields.length) {
                    this.rows = [
                        this.selectedFields.reduce((acc, f) => ({ ...acc, [f]: 'No Records' }), { Id: '—' })
                    ];
                }
                this.enableInfiniteScroll = false;
            } else {
                // Enable lazy loading only if data exists
                this.loadNextBatch();
            }
        } else if (result.error) {
            this.allRecords = [];
            this.rows = [];
            this.enableInfiniteScroll = false;

            const msg = this.getErrorMessage(result.error);

            if (msg.includes('No such column') || msg.includes('object not allowed')) {
                if (this.selectedFields.length) {
                    this.rows = [
                        this.selectedFields.reduce((acc, f) => ({ ...acc, [f]: 'No Records' }), { Id: '—' })
                    ];
                }
            } else {
                this.showToast('Error', msg, 'error');
            }
        }

        this.loading = false;
    }

    loadNextBatch() {
        const nextBatch = this.allRecords.slice(this.currentOffset, this.currentOffset + this.rowLimit);
        this.rows = [...this.rows, ...nextBatch];
        this.currentOffset += nextBatch.length;
        this.enableInfiniteScroll = this.currentOffset < this.allRecords.length;
    }

    handleLoadMore(event) {
        if (this.isLoadingMore || !this.enableInfiniteScroll) return;

        this.isLoadingMore = true;
        event.target.isLoading = true;

        setTimeout(() => {
            this.loadNextBatch();
            this.isLoadingMore = false;
            event.target.isLoading = false;
            if (!this.enableInfiniteScroll) {
                event.target.enableInfiniteLoading = false;
            }
        }, 300);
    }

    async handleInlineSave(event) {
        const updatedFields = event.detail.draftValues;
        if (!updatedFields || updatedFields.length === 0) return;

        this.loading = true;
        try {
            const payload = updatedFields.map(dv => ({ sobjectType: this.selectedObject, fields: { ...dv } }));
            const result = await updateRecords({ updates: payload });

            const successCount = result.filter(r => r.success).length;
            const failCount = result.length - successCount;

            if (successCount > 0) this.showToast('Success', `${successCount} record(s) updated successfully.`, 'success');
            if (failCount > 0) this.showToast('Warning', `${failCount} record(s) failed to update.`, 'warning');

            this.draftValues = [];
            if (this.wiredRecordsResult) await refreshApex(this.wiredRecordsResult);
        } catch (err) {
            this.showToast('Error', this.getErrorMessage(err), 'error');
        } finally {
            this.loading = false;
        }
    }

    resetData() {
        this.rows = [];
        this.columns = [];
        this.allRecords = [];
        this.currentOffset = 0;
        this.enableInfiniteScroll = false;
        this.draftValues = [];
        this.errorMessage = '';
    }

    getErrorMessage(err) {
        return err?.body?.message || err?.message || JSON.stringify(err);
    }

    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get showDatatable() {
        return this.rows && this.rows.length > 0 && this.columns && this.columns.length > 0;
    }
}