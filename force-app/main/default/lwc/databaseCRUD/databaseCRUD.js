import { LightningElement, api, track, wire } from 'lwc';
import getChildDetails from '@salesforce/apex/GetContactOpportunityDetail.getChildDetails';
import createContact from '@salesforce/apex/GetContactOpportunityDetail.createContact';
import deleteContact from '@salesforce/apex/GetContactOpportunityDetail.deleteContact';
import deletecontactfirst from '@salesforce/apex/GetContactOpportunityDetail.deletecontactfirst';
import updateContacts from '@salesforce/apex/GetContactOpportunityDetail.updateContacts';
import updateContact from '@salesforce/apex/GetContactOpportunityDetail.updateContact'; // ✅ missing one
import Updatecontactbyid from '@salesforce/apex/GetContactOpportunityDetail.Updatecontactbyid';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi'; // ✅ required for handleSave
import { refreshApex } from '@salesforce/apex'; // ✅ required for refreshing wired data


const columns1 = [
    { label: 'Opportunity Id', fieldName: 'Id' },
    { label: 'Opportunity Name', fieldName: 'Name', editable: true }
];
const columns2 = [
    { label: 'Name', fieldName: 'LastName', type: 'text', editable: true },
    { label: 'Email', fieldName: 'Email', type: 'email', editable: true },
    { label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true },
    {
        type: 'action',
        typeAttributes: { rowActions: [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ]}
    }
];


// const columns = [
//     {
//         label: 'Name',
//         fieldName: 'Name',
//         type: 'text',
//     }, {
//         label: 'FirstName',
//         fieldName: 'FirstName',
//         type: 'text',
//         editable: true,
//     }, {
//         label: 'LastName',
//         fieldName: 'LastName',
//         type: 'text',
//         editable: true,
//     }, {
//         label: 'Phone',
//         fieldName: 'Phone',
//         type: 'phone',
//         editable: true
//     }
// ];

export default class DatabaseCRUD extends LightningElement {
    @api recordId;
    @track opportunityData = [];
    @track contactData = [];
    @track newContactName = '';
    @track updateContactName='';
    @track isLoading = false;
    @track updateContactNamebyid='';
    
    @track draftValues = [];
    @track contacts;
    saveDraftValues = [];



    
    contactIdToDelete = '';
    @track updateid='';

    columns1 = columns1;
    columns2 = columns2;





    connectedCallback() {
        console.log("recordId in LWC:", this.recordId);
        if (this.recordId) {
            this.loadData();
        }
    }

    // Capture user input
    handleNameChange(event) {
        this.newContactName = event.target.value;
    }

    // handleContactSave(event) {
    //     this.handleSave(event);
    // }
    
    handleUpdateid(event) {
        this.updateid = event.target.value;
    }
    handleUpdateContactNameById(event) {
        this.updateContactNamebyid = event.target.value;
    }
    handleUpdateContactName(event) { // <-- Added missing handler for update by name
        this.updateContactName = event.target.value;
    }
    handleContactIdChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;

        if (fieldName === 'Delete') {
            this.contactIdToDelete = value;
        }
        // // const fieldName = event.target.name;
        // // const fieldValue = event.target.value;

        // this.actionName = event.target.name;
        // const value = event.target.value;
    
        // switch (actionName) {
        //     // case 'update':
        //     //     this.updateContactName=value;
        //     //     break;
        //     case 'Delete':
        //         this.contactIdToDelete=value;
        //         break;
        // }
    }


    // Load related data
    loadData() {
        this.isLoading = true;
        getChildDetails({ recId: this.recordId })
            .then(result => {
                console.log("Data received:", JSON.stringify(result));
                if (result && result.length > 0) {
                    this.contactData = result[0].Contacts;
                    this.opportunityData = result[0].Opportunities;
                    console.log('hiiiiiiiiiii',this.contactData);
                }
            })
            .catch(error => {
                console.error("Error:", error);
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    // Row Actions for Datatable
    // --------------------- INLINE SAVE ---------------------
    handleSaveContactInline(event) {
        const updatedFields = event.detail.draftValues;
        console.log('data: '+ JSON.stringify(updatedFields));
        updateContacts({ contacts: updatedFields })
            .then(() => {
                this.showToast('Success', 'Contacts updated successfully', 'success');
                this.draftValues = [];
                this.loadData();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }
    
    handleSave(event) {
        this.saveDraftValues = event.detail.draftValues;
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
 
        // Updateing the records using the UiRecordAPi
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.showToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
            this.saveDraftValues = [];
            return this.refresh();
        }).catch(error => {
            this.showToast('Error', 'An Error Occured!!', 'error', 'dismissable');
        }).finally(() => {
            this.saveDraftValues = [];
        });
    }
 

    // --------------------- ROW ACTIONS ---------------------
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'edit':
                this.showToast('Info', 'Use pencil to inline edit, then Save.', 'info');
                break;
            case 'delete':
                    this.handleDeleteContact(row.Id);
                    break;
                
            default:
        }
    }
 


    
    handleUpdateContact(){
        console.log('Insert button clicked, name:', this.updateContactName);
        if(!this.updateContactName){
            this.showToast('error','Please enter a contact name','error');
            return;
        }
        updateContact({accId :this.recordId, upName:this.updateContactName})
        .then(result=>{
            console.log('updated succefully',JSON.stringify(result));
            this.showToast('success','Updated succefully','success');
            this.updateContactName='';
            this.loadData();
        })
        .catch(error => {
            console.error("Insert contact failed:", JSON.stringify(error));
            this.showToast('Error', error.body.message, 'error');
        });
    }
    handleUpdateById(){
        console.log('Insert button clicked, name:', this.updateContactNamebyid);
        if(!this.updateid){
            this.showToast('Error','enter a update id ','error');
            return;
        }
        Updatecontactbyid({ conid: this.updateid, Lastname:this.updateContactNamebyid})

        .then((result)=>{
            
            
            
            console.log('updated successfully by id ',JSON.stringify(result));
            this.updateContactNamebyid='';
            this.showToast('Success','contact is updated yayyy!','success');
            this.loadData();
        })
        .catch(error => {
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast('Error', message, 'error');
        });

    }



    // Insert Contact with user input
    handleInsertContact() {
        console.log('Insert button clicked, name:', this.newContactName);

        if (!this.newContactName) {
            this.showToast('Error', 'Please enter a contact name', 'error');
            return;
        }

        createContact({ accId: this.recordId, conName: this.newContactName })
            .then(result => {
                console.log('Contact inserted:', JSON.stringify(result));
                this.showToast('Success', 'Contact inserted successfully', 'success');
                this.newContactName = ''; // reset input
                this.loadData();
            })
            .catch(error => {
                console.error("Insert contact failed:", JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
            });
    }


    // Delete Contact
     
    

    handleDeleteById() { 
        if (!this.contactIdToDelete) {
            this.showToast('Error', 'Enter a Contact Id', 'error');
            return;
        }
        deleteContact({ contactId: this.contactIdToDelete })
            .then(() => {
                this.showToast('Success', 'Contact deleted successfully', 'success');
                this.contactIdToDelete = '';
                this.loadData();
            })
            .catch(error => {
                this.showToast('Delete failed', error.body.message, 'error');
            });
    }
    

    // Row action delete
    

    handleDeleteContact(contactId) {
        if (!contactId) return;
        // If no contactId is provided, delete first contact in list
        if (!contactId) {
            if (this.contactData.length === 0) {
                this.showToast('Error', 'No contacts to delete', 'error');
                return;
            }
            contactId = this.contactData[0].Id;
        } 
    
        deletecontactfirst({ accId: this.recordId })
            

            .then(result => {
                if(result === 'success'){
                    this.showToast('Success', 'Contact deleted successfully', 'success');
                }
                
                // this.showToast('Info', result, 'info');

                this.loadData(); // refresh data after delete
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }
    
    

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    // This function is used to refresh the table once data updated
    async refresh() {
        await refreshApex(this.contacts);
    }
    
}