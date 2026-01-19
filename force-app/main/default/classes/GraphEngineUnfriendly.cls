/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-19-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
// ===================== PMD & CPD Violations =====================
// PMD: High cyclomatic complexity, long methods, nested ifs
// CPD: Code duplication

public with sharing class GraphEngineUnfriendly {

    // Inefficient entry point
    @AuraEnabled
    public static void processData(Boolean b1, Boolean b2, Boolean b3) {
        // Nested ifs -> path explosion
        if(b1) {
            if(b2) {
                if(b3) {
                    helperA();
                } else {
                    helperB();
                }
            } else {
                if(b3) {
                    helperC();
                } else {
                    helperD();
                }
            }
        } else {
            if(b2) {
                if(b3) {
                    helperE();
                } else {
                    helperF();
                }
            } else {
                if(b3) {
                    helperG();
                } else {
                    helperH();
                }
            }
        }
    }

    public static void helperA(){System.debug('A');}
    public static void helperB(){System.debug('B');}
    public static void helperC(){System.debug('C');}
    public static void helperD(){System.debug('D');}
    public static void helperE(){System.debug('E');}
    public static void helperF(){System.debug('F');}
    public static void helperG(){System.debug('G');}
    public static void helperH(){System.debug('H');}

    // ===================== CPD: Duplicate code =====================
    public static void duplicateLogic1() {
        System.debug('Duplicate Logic');
        System.debug('Duplicate Logic');
        System.debug('Duplicate Logic');
    }
    public static void duplicateLogic2() {
        System.debug('Duplicate Logic');
        System.debug('Duplicate Logic');
        System.debug('Duplicate Logic');
    }
}

// ===================== JS Example =====================
// ESLint & RetireJS violations, Regex anti-pattern

var fs = require('fs');  // RetireJS: old/unsafe dependency
var path = require('path');

function unsafeJS(input) {
    // ESLint: no-unused-vars, no-undef
    var data = fs.readFileSync('data.txt'); 
    var regex = /<script>.*<\/script>/; // Regex vulnerability: unsafe pattern

    if(input == 'test'){ console.log("Test"); } else { console.log("Not Test"); }

    // CPD: repeated code block
    console.log("Duplicate log");
    console.log("Duplicate log");
    console.log("Duplicate log");
}

// Flow type violation
function addNumbers(a, b) {
    // Flow: no type annotation
    return a + b;
}
