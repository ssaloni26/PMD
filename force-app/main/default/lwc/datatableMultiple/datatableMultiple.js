import { LightningElement,api } from 'lwc';
import getChildDetails from '@salesforce/apex/GetContactOpportunityDetails.getChildDetails';


//declarinng columns for opportunity dt
const columns1=[
    {label:"Opportunity Id", fieldName:'Id'},
    {label:"Opoortunity Name",fieldName:'Name'},
]
//declarinng columns for contact dt
const columns2=[
    {label:"Contact Id", fieldName:'Id'},
    {label:"Contact Name",fieldName:'Name'},
]
export default class DatatableMultiple extends LightningElement {
    @api buttonLabel ="show";

    opportunityData=[];//array will be stored in opps details
    contactData=[];//array for contact details

    columns1=columns1;
    columns2=columns2;

    @api recordId;
    @api showDatatable=false;

    opportunityTempArray=[]; //array will be stored in opps details
    contactTempArray=[]; 

    handleShow(event){
        //show button
        if(event.target.label == "show"){
            this.buttonLabel ="hide";
            this.showDatatable=true;
        }
        //hide button
        else if(event.target.label =="hide")
            {
                this.buttonLabel = "show";
                this.showDatatable=false;
            }
    }

    connectedCallback()
    {
        //calleing apex method by recordid
        getChildDetails({recId:this.recordId})
        .then(res =>{
            let tempRecords = res;
            console.log("temp records:"+JSON.stringify(tempRecords));

            //create 2 object for storing opportunities and contacts details
            let temp = tempRecords.map(row=>{
                return Object.assign({oppname: row.Opportunities, contactName:row.Contacts})
            })

            console.log("temp "+JSON.stringify(temp));

            //store opportunities and contacts details in diff array
            temp.forEach(element => {
                this.opportunitiesTempArray = element.oppname;
                console.log("opportunity temp array:"+JSON.stringify(this.opportunityTempArray));

                this.contactTempArray = element.contactName;
                console.log("contact temp array:"+JSON.stringify(this.contactTempArray));
                        });
            this.opportunityData=this.opportunitiesTempArray;
            this.contactData=this.contactTempArray;

        })
        .catch(error =>{
            console.error("error:"+JSON.stringify(error));
        })
    }
}