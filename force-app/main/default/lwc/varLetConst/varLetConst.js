import { LightningElement } from 'lwc';

export default class VarLetConst extends LightningElement {
        message;   // to display result in UI

    connectedCallback() {
        // -------- VAR --------
        // var has function scope (or global scope if outside a function).
        // It can be re-declared and updated.
        var x = 10;
        console.log('var x = ' + x);
        x = 20; // ✅ can be updated
        console.log('var x = ' + x);
        var x = 30; // ✅ can be redeclared
        console.log('var x = ' + x);

        // -------- LET --------
        // let has block scope.
        // It can be updated but NOT redeclared in the same scope.
        let y = 40;
        console.log('let y = ' + y);
        y = 50; // ✅ can be updated
        // let y = 60; ❌ Error if redeclared in same block
        console.log('let y = ' + y);

        // -------- CONST --------
        // const has block scope.
        // It CANNOT be updated or redeclared.
        const z = 70;
        // z = 80; ❌ Error - cannot update
        console.log('const z = ' + z);

        this.message = `var x = ${x}, let y = ${y}, const z = ${z}`;
    }
}