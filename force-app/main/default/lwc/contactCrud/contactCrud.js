import { LightningElement, track, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactController.getContacts';
import getContactCount from '@salesforce/apex/ContactController.getContactCount';
import deleteContact from '@salesforce/apex/ContactController.deleteContact';
import updateContacts from '@salesforce/apex/ContactController.updateContacts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class ContactCrud extends LightningElement {
    @track contacts = [];
    @track draftValues = [];
    @track selectedRows = [];
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track contactRecord = { Id: '', FirstName: '', LastName: '', Email: '', Phone: '', AccountId: '' };
    @track isModalOpen = false;

    wiredContactResult;

    @track columns = [
        { label: 'First Name', fieldName: 'FirstName', editable: true },
        { label: 'Last Name', fieldName: 'LastName', editable: true },
        { label: 'Email', fieldName: 'Email', type: 'email', editable: true },
        { label: 'Phone', fieldName: 'Phone', type: 'text', editable: true },
        {
            label: 'Account',
            fieldName: 'AccountName',
            type: 'customLookup',
            editable: true,
            typeAttributes: {
                placeholder: 'Select Account',
                objectApiName: 'Account',
                defaultRecordId: { fieldName: 'AccountId' },
                defaultRecordName: { fieldName: 'AccountName' },
                rowId: { fieldName: 'Id' }
            }
        },
        {
            type: 'action',
            typeAttributes: { rowActions: [
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
            ]}
        }
    ];

    // **Wire contacts dynamically based on pageNumber**
    @wire(getContacts, { pageSize: 11, offsetRecords: '$offsetRecords' })
    wiredContacts(result) {
        this.wiredContactResult = result;
        if (result.data) {
            this.contacts = result.data.map(c => ({
                ...c,
                AccountName: c.Account ? c.Account.Name : '',
                AccountId: c.AccountId
            }));
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }

    // Calculate offset dynamically based on pageNumber
    get offsetRecords() {
        return this.pageNumber === 1 ? 0 : 11 + (this.pageNumber - 2) * 10;
    }

    connectedCallback() {
        this.loadTotalCount();
    }

    loadTotalCount() {
        getContactCount()
            .then(result => {
                this.totalRecords = result;
                this.totalPages = this.totalRecords <= 11 ? 1 : 1 + Math.ceil((this.totalRecords - 11) / 10);
            })
            .catch(error => console.error(error));
    }

    refreshAllData() { 
        this.loadTotalCount();
        if (this.wiredContactResult) {
            refreshApex(this.wiredContactResult);
        }
    }

    handleNext() { if (this.pageNumber < this.totalPages) { this.pageNumber++; refreshApex(this.wiredContactResult); } }
    handlePrevious() { if (this.pageNumber > 1) { this.pageNumber--; refreshApex(this.wiredContactResult); } }
    handleFirst() { this.pageNumber = 1; refreshApex(this.wiredContactResult); }
    handleLast() { this.pageNumber = this.totalPages; refreshApex(this.wiredContactResult); }

    get isFirstPage() { return this.pageNumber === 1; }
    get isLastPage() { return this.pageNumber === this.totalPages; }

    handleNew() {
        this.contactRecord = { Id: '', FirstName: '', LastName: '', Email: '', Phone: '', AccountId: '' };
        this.isModalOpen = true;
    }

    handleEdit(event) {
        const recordId = event.target.dataset.id;
        const contact = this.contacts.find(c => c.Id === recordId);
        this.contactRecord = { ...contact };
        this.isModalOpen = true;
    }

    handleDelete(event) {
        const recordId = event.target.dataset.id;
        deleteContact({ contactId: recordId })
            .then(() => {
                this.showToast('Success', 'Contact deleted successfully', 'success');
                this.refreshAllData();
            })
            .catch(error => this.showToast('Error', error.body ? error.body.message : error.message, 'error'));
    }

    handleDeleteSelected() {
        if (this.selectedRows.length === 0) {
            this.showToast('Error', 'Please select at least one contact to delete.', 'error');
            return;
        }
        Promise.all(this.selectedRows.map(id => deleteContact({ contactId: id })))
            .then(() => {
                this.showToast('Success', 'Selected contacts deleted successfully.', 'success');
                this.selectedRows = [];
                this.refreshAllData();
            })
            .catch(error => this.showToast('Error', error.body ? error.body.message : error.message, 'error'));
    }

    handlePhoneChange(event) { this.contactRecord.Phone = event.target.value.replace(/\D/g, ''); }

    handleSubmit(event) {
        const phone = this.contactRecord.Phone;
        if (!phone) { event.preventDefault();  return; }
        if (!/^\d{10}$/.test(phone)) { event.preventDefault(); this.showToast('Error', 'Phone number must be exactly 10 digits.', 'error'); return; }
    }

    handleSaveSuccess() {
        this.showToast('Success', 'Contact saved successfully', 'success');
        this.isModalOpen = false;
        this.refreshAllData();
    }

    handleSaveError(event) { this.showToast('Error', event.detail.detail, 'error'); }
    handleClose() { this.isModalOpen = false; }

    showToast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'edit') { this.handleEdit({ target: { dataset: { id: row.Id } } }); }
        else if (actionName === 'delete') { this.handleDelete({ target: { dataset: { id: row.Id } } }); }
    }

    handleLookupChange(event) {
        const { selectedRecordId, selectedRecordName, rowId } = event.detail;
        let draft = this.draftValues.find(d => d.Id === rowId);
        if (!draft) {
            draft = { Id: rowId };
            this.draftValues.push(draft);
        }
        draft.AccountId = selectedRecordId;
        draft.AccountName = selectedRecordName;
    }

    handleInlineSave(event) {
        const updatedFields = event.detail.draftValues;

        for (let row of updatedFields) {
            if (row.Phone && !/^\d{10}$/.test(row.Phone)) {
                alert(`Phone number for ${row.FirstName || ''} must be exactly 10 digits.`);
                return;
            }
        }

        updateContacts({ contacts: updatedFields })
            .then(() => {
                this.showToast('Success', 'Contacts updated successfully', 'success');
                this.draftValues = [];
                this.refreshAllData();
            })
            .catch(error => this.showToast('Error', error.body ? error.body.message : error.message, 'error'));
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.Id);
    }
}