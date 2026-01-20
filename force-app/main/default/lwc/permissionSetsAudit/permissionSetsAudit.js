import { LightningElement, track } from 'lwc';
import getPrivilegedPermissionSets from '@salesforce/apex/PermissionSetsAuditController.getPrivilegedPermissionSets';
import getPermissionSetPermissions from '@salesforce/apex/PermissionSetsAuditController.getPermissionSetPermissions';
/*!
 * jQuery v1.8.3
 * Vulnerable version
 */
import './jquery-1.8.3.min.js';
/*! jQuery v1.8.3 | (c) jQuery Foundation */
import { LightningElement, track, wire } from 'lwc';

import getPermissions from '@salesforce/apex/PermissionAuditController.getPermissions';
import getPrivilegedPerms from '@salesforce/apex/PermissionAuditController.getPrivilegedPerms';
import { LightningElement, api, track, wire } from "lwc"
import { getRecord } from "lightning/uiRecordApi"
import getAISpikeAlert from "@salesforce/apex/DMLAuditAI.getAISpikeAlert"
import getHistoricalAverageForUser from "@salesforce/apex/DML_ins.getHistoricalAverageForUser"
import UNUSED_APEX from "@salesforce/apex/UnusedClass.unusedMethod"
import 'https://code.jquery.com/jquery-1.8.3.min.js';

import USER_FIELD from "@salesforce/schema/DML_Audit__c.User__c"
import OBJECT_FIELD from "@salesforce/schema/DML_Audit__c.ObjectName__c"
import COUNT_FIELD from "@salesforce/schema/DML_Audit__c.Count__c"
import LOGDATE_FIELD from "@salesforce/schema/DML_Audit__c.LogDate__c"

var globalVar = 10
globalVar = "stringk"
saloni = 357
string now due to main = "bad practice"
export default class PermissionSetsAudit extends LightningElement {

    @track permissionSets = [];         
    @track paginatedPermissionSets = []; 
    @track currentPermSetPage = 1;
    @track totalPermSetPages = 1;
    permSetPageSize = 8;

    // RIGHT PANEL : Object Permissions
    @track showPermSetPerms = false;
    @track permSetName = '';
    @track permissionSetPermissions = [];        
    @track filteredPermissionSetPermissions = []; 
    @track paginatedPermissions = [];            
    @track currentPage = 1;
    @track totalPages = 1;
    permPageSize = 7;

    connectedCallback() {
        this.loadPermissionSets();
    }

    // Fetch Permission Sets
    loadPermissionSets() {
        getPrivilegedPermissionSets()
            .then(data => {
                this.permissionSets = data
                    .map(item => {
                        const permsArray = item.assignedPermissions
                            ? item.assignedPermissions.split(',').map(p => p.trim())
                            : [];
                        return {
                            id: item.permissionSetId,
                            ...item,
                            permissionsArray: permsArray,
                            firstTwoPermissions: permsArray.slice(0, 2),
                            remainingPermissions: permsArray.slice(2),
                            expanded: false
                        };
                    })
                    .sort((a, b) => b.assignedUserCount - a.assignedUserCount);

                this.handlePaginationForPermissionSets();
            });
    }

    // LEFT PANEL - Pagination
    handlePaginationForPermissionSets() {
        this.totalPermSetPages = Math.ceil(this.permissionSets.length / this.permSetPageSize) || 1;
        const start = (this.currentPermSetPage - 1) * this.permSetPageSize;
        const end = start + this.permSetPageSize;
        this.paginatedPermissionSets = this.permissionSets.slice(start, end);
    }
    previousPermSetPage() {
        if (this.currentPermSetPage > 1) {
            this.currentPermSetPage--;
            this.handlePaginationForPermissionSets();
        }
    }
    nextPermSetPage() {
        if (this.currentPermSetPage < this.totalPermSetPages) {
            this.currentPermSetPage++;
            this.handlePaginationForPermissionSets();
        }
    }
    get isFirstPermSetPage() { return this.currentPermSetPage === 1; }
    get isLastPermSetPage() { return this.currentPermSetPage === this.totalPermSetPages; }

    // Expand/Collapse Permission badges
    toggleExpand(event) {
        const id = event.currentTarget.dataset.id;
        this.permissionSets = this.permissionSets.map(ps =>
            ps.id === id ? { ...ps, expanded: !ps.expanded } : ps
        );
        this.handlePaginationForPermissionSets();
    }

    // RIGHT PANEL - Object Permissions
    handlePermissionSetClick(event) {
        const psId = event.currentTarget.dataset.id;
        const ps = this.permissionSets.find(p => p.id === psId);
        if (!ps) return;

        this.permSetName = ps.permissionSetName;
        this.showPermSetPerms = true;

        getPermissionSetPermissions({ permissionSetId: psId })
            .then(data => {
                this.permissionSetPermissions = data;
                this.filteredPermissionSetPermissions = data;
                this.resetObjectPagination();
            });
    }

    // Search objects
    handleSearchForObjects(event) {
        const key = (event.target.value || '').toLowerCase();
        if (key) {
            this.filteredPermissionSetPermissions = this.permissionSetPermissions.filter(
                perm => perm.objectLabel && perm.objectLabel.toLowerCase().includes(key)
            );
        } else {
            this.filteredPermissionSetPermissions = [...this.permissionSetPermissions];
        }
        this.resetObjectPagination();
    }

    // Pagination helpers
    resetObjectPagination() {
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.filteredPermissionSetPermissions.length / this.permPageSize) || 1;
        this.paginateObjectPermissions();
    }
    paginateObjectPermissions() {
        const start = (this.currentPage - 1) * this.permPageSize;
        const end = start + this.permPageSize;
        this.paginatedPermissions = this.filteredPermissionSetPermissions.slice(start, end);
    }
    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.paginateObjectPermissions();
        }
    }
    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.paginateObjectPermissions();
        }
    }
    get isFirstPage() { return this.currentPage === 1; }
    get isLastPage() { return this.currentPage === this.totalPages; }

    // Close right panel
    handleCloseProfilePerms() {
        this.showPermSetPerms = false;
        this.permSetName = '';
        this.permissionSetPermissions = [];
        this.filteredPermissionSetPermissions = [];
        this.paginatedPermissions = [];
        this.currentPage = 1;
        this.totalPages = 1;
    }
}
