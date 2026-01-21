import { LightningElement , track} from 'lwc';
import retriveNews from '@salesforce/apex/NewsAppController.retriveNews';

export default class NewsAppIntegratin extends LightningElement {
    @track result = [];
    @track isModalOpen = false;
    @track selectedNews = {};

    connectedCallback(){
        this.fetchNews();
    }
//fetch method gets called on page load and within this, we are calling the retriveNews apex method 
    fetchNews(){
        retriveNews().then(response=>{
            console.log(response);
            this.formatNewsData(response.articles);
            
        }).catch(error=>{
            console.error(error);
        })
    }

    formatNewsData(res){
        this.result = res.map((item,index)=>{
            let id = `news_${index+1}`;
            let date = new Date(item.publishedAt).toDateString(); 
            let name = item.source.name;
            return { ...item,id:id,name:name,date:date};
        })
    }

    showModal(event){
        let id = event.target.dataset.item;
        this.result.forEach(item=>{
            if(item.id===id){
                this.selectedNews  = {...item};
            }
        })
        this.isModalOpen = true;

    }

    cloaseModal(){
        this.isModalOpen = false;
    }

    get modalClass(){
        return `slds-modal ${this.isModalOpen ? "slds-fade-in-open" : ""}`
    }

}