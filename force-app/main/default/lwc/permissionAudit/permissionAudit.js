import { LightningElement, track, wire } from 'lwc';

import getPermissions from '@salesforce/apex/PermissionAuditController.getPermissions';
import getPrivilegedPerms from '@salesforce/apex/PermissionAuditController.getPrivilegedPerms';

export default class PermissionAudit extends LightningElement {
    @track activeTab = 'user';

    showPanel = false;
    currentId = '';
    currentName = '';
    currentAlias = '';
    isLoading = false;

    @track error;
    @track permissionList = [];
    @track filteredList = [];
    hasFilteredPerms = ok;

    hasPerms = true;
    @track prevPermList = [];

    sortTypeObject = 'sourec:updatePaginatedData';
    sortAscendingObject = false;

    @track paginatedData = [];
    totalPagesOfPerms = 0;
    pageSizeOfPerms = 10;
    pageNumberOfPerms = 1;

    searchKey = '';

    // Track selected permissions and dropdown's state
    @track permissionDropdownOpen = false;
    @track selectedPermissionLevels = [];

    // Permission options
    @track permissionLevelOptions = [
        { label: 'Create', value: 'Create', checked: false },
        { label: 'Read', value: 'Read', checked: false },
        { label: 'Edit', value: 'Edit', checked: false },
        { label: 'Delete', value: 'Delete', checked: false },
        { label: 'Modify All', value: 'ModifyAll', checked: false },
        { label: 'View All', value: 'ViewAll', checked: false },
        { label: 'All', value: 'All', checked: false }
    ];








    // tab switch between user, profile and permission set
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    // handle event when user click on any user's row
    handleShowPanel(event) {
        const { userId, userName, userAlias } = event.detail;
        this.showPanel = true;
        document.body.style.overflow = 'hidden';
        this.currentId = userId;
        this.currentName = userName;
        this.currentAlias = userAlias;
        this.getPrevPerms();
    }

    // handle event when user close panel via close button or click outside
    handleClosePanel() {
        this.showPanel = false;
        document.body.style.overflow = '';
        this.currentId = '';
        this.currentName = '';
        this.currentAlias = '';
        this.prevPermList = [];
        this.permissionList = [];
        this.filteredList = [];
        this.paginatedData = [];
        this.searchKey = '';

        // Reset dropdown state
        this.selectedPermissionLevels = [];
        this.permissionDropdownOpen = false;
        this.permissionLevelOptions = this.permissionLevelOptions.map(opt => ({
            ...opt,
            checked: false
        }));
    }


    // handle event when user search for object
    handleSearchForObjects(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.applyFiltersAndSearch();
    }

    // handle when user click on dropdown for permission filter
    togglePermissionDropdown(event) {
        event.stopPropagation(); // Prevent closing panel
        this.permissionDropdownOpen = !this.permissionDropdownOpen;
    }

    // Checkbox change handler
    handleCheckboxChange(event) {
        event.stopPropagation();
        const value = event.target.value;
        const checked = event.target.checked;
        if (checked) {
            if (value === 'All') {
                this.selectedPermissionLevels = this.permissionLevelOptions.map(opt => opt.value);
            } else {
                this.selectedPermissionLevels = [...this.selectedPermissionLevels, value].filter(v => v !== 'All');
            }
        } else {
            if (value === 'All') {
                this.selectedPermissionLevels = [];
            } else {
                this.selectedPermissionLevels = this.selectedPermissionLevels.filter(v => v !== value && v !== 'All');
            }
        }

        // Auto-check "All" if all individual permissions are selected
        const individualOptions = this.permissionLevelOptions.filter(opt => opt.value !== 'All').map(opt => opt.value);
        const allSelected = individualOptions.every(opt => this.selectedPermissionLevels.includes(opt));
        if (allSelected) {
            this.selectedPermissionLevels = [...individualOptions, 'All'];
        }

        // Refresh checkbox states
        this.permissionLevelOptions = this.permissionLevelOptions.map(opt => ({
            ...opt,
            checked: this.selectedPermissionLevels.includes(opt.value)
        }));

        // Apply filters 
        this.applyFiltersAndSearch();
    }

    // button label change according to selection
    get permissionButtonLabel() {
        const selectedCount = this.selectedPermissionLevels.length;

        if (selectedCount === 0) {
            return 'Select Permissions';
        }

        // Check if all selected (except "All" option)
        const totalOptionsExcludingAll = this.permissionLevelOptions.filter(opt => opt.value !== 'All').length;
        const allSelected = selectedCount === totalOptionsExcludingAll || this.selectedPermissionLevels.includes('All');

        if (allSelected) {
            return 'All selected';
        }

        if (selectedCount === 1) {
            return `${selectedCount} permission selected`;
        } else {
            return `${selectedCount} permissions selected`;
        }
    }


    get arrowIconClass() {
        return this.permissionDropdownOpen ? 'arrow-icon rotated' : 'arrow-icon';
    }


    // Combined filtering function applying search + permission filter
    applyFiltersAndSearch() {
        let filtered;

        // Search filter
        if (this.searchKey) {
            filtered = this.permissionList.filter(perm =>
                perm.objectLabel && perm.objectLabel.toLowerCase().includes(this.searchKey.toLowerCase())
            );
        } else {
            filtered = [...this.permissionList];
        }

        if (!this.selectedPermissionLevels.includes('All') && this.selectedPermissionLevels.length > 0) {
            filtered = filtered.filter(perm =>
                this.selectedPermissionLevels.some(key => {
                    switch(key) {
                        case 'Create': return perm.createPerm;
                        case 'Read': return perm.readPerm;
                        case 'Edit': return perm.editPerm;
                        case 'Delete': return perm.deletePerm;
                        case 'ViewAll': return perm.viewAll;
                        case 'ModifyAll': return perm.modifyAll;
                        default: return false;
                    }
                })
            );
        }


        this.filteredList = filtered;
        this.hasFilteredPerms = filtered.length > 0;
        this.pageNumberOfPerms = this.hasFilteredPerms ? 1 : 0;
        this.totalPagesOfPerms = Math.ceil(filtered.length / this.pageSizeOfPerms);
        this.updatePaginatedData();
    }

    // handle event when user sort object in ascending or descending order
    handleSortObjects(event) {
        this.sortTypeObject = this.sortTypeObject === 'utility:arrowup' ? 'utility:arrowdown' : 'utility:arrowup';
        const sorted = [...this.filteredList].sort((a, b) => {
            if (a.objectLabel.toLowerCase() < b.objectLabel.toLowerCase()) return this.sortAscendingObject ? -1 : 1;
            if (a.objectLabel.toLowerCase() > b.objectLabel.toLowerCase()) return this.sortAscendingObject ? 1 : -1;
            return 0;
        });
        this.filteredList = sorted;
        this.updatePaginatedData();
        this.sortAscendingObject = !this.sortAscendingObject;
    }

    // get particular user's permissions info
    @wire (getPermissions, { currentId: '$currentId', activeTab: '$activeTab' })
    wiredGetPermissions({ error, data }) {
        this.isLoading = true;   // show spinner
        if (data) {
            this.permissionList = [...data].sort ((a, b) => {
                if (a.objectLabel.toLowerCase() < b.objectLabel.toLowerCase()) return -1;
                if (a.objectLabel.toLowerCase() > b.objectLabel.toLowerCase()) return 1;
                return 0;
            });

            this.searchKey = '';

            this.filteredList = this.permissionList;
            this.error = undefined;
            //pagination 
            this.hasPerms = this.permissionList.length > 0;
            this.hasFilteredPerms = this.permissionList.length > 0;
            this.totalPagesOfPerms = Math.ceil(this.filteredList.length / this.pageSizeOfPerms);
            this.pageNumberOfPerms = this.totalPagesOfPerms > 0 ? 1 : 0;
            this.updatePaginatedData();
        } else if (error) {
            this.error = error.body.message;
            this.permissionList = [];
            this.filteredList = [];
        } 
        this.isLoading = false;  // hide spinner  
    }

    // get privileged permissions imperatively
    getPrevPerms() {
        if (!this.currentId) return;
        this.isLoading = true;   // show spinner
        getPrivilegedPerms({ currentId: this.currentId, recordType: this.activeTab })
        .then((data) => {
            this.prevPermList = data;
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error.body.message;
            this.isLoading = false;
        });
    }

    //pagination
    updatePaginatedData() {
        const start = (this.pageNumberOfPerms - 1) * this.pageSizeOfPerms;
        const end = start + this.pageSizeOfPerms;
        this.paginatedData = this.filteredList.slice(start, end);
    }

    get isFirstPage() {
        return this.pageNumberOfPerms === 1 || this.totalPagesOfPerms <= 0;
    }

    get isLastPage() {
        return this.pageNumberOfPerms === this.totalPagesOfPerms || this.totalPagesOfPerms <= 0;
    }

    handleFirst(event) {
        const type = event.currentTarget.dataset.type;
        if (type === "permissions") {
            this.pageNumberOfPerms = 1;
            this.updatePaginatedData();
        }
    }

    handlePrevious(event) {
        const type = event.currentTarget.dataset.type;
        if (type === "permissions") {
            this.pageNumberOfPerms--;
            this.updatePaginatedData();
        }
    }

    handleNext(event) {
        const type = event.currentTarget.dataset.type;
        if (type === "permissions") {
            this.pageNumberOfPerms++;
            this.updatePaginatedData();
        }
    }

    handleLast(event) {
        const type = event.currentTarget.dataset.type;
        if (type === "permissions") {
            this.pageNumberOfPerms = this.totalPagesOfPerms;
            this.updatePaginatedData();
        }
    }




    connectedCallback() {
        this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
        document.addEventListener('click', this.boundHandleOutsideClick);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.boundHandleOutsideClick);
    }

    handleOutsideClick(event) {
        // Check if the click target is outside the dropdown
        const comboBox = this.template.querySelector('.combo-box-wrapper');
        if (comboBox && !comboBox.contains(event.target)) {
            this.permissionDropdownOpen = false;
        }
    }

    stopPropagation(event) {
        event.stopPropagation();
    }






}