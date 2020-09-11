public class BuildMergeContact {
    
    @AuraEnabled
    public static List<conChildObjNames> fetchRelatedList(String filterString ) {
        List<conChildObjNames> returnRelatedList = new List<conChildObjNames>();
        Schema.DescribeSObjectResult r = null;
        List<conChildObjNames> options = new List<conChildObjNames>();
        //string apiName;
        list<string> ObjApiName = new list<string>();					
        List<string> notSupportedObj=new List<string>{'OpportunityOld', 'Work Order Change Event', 'User Change Event', 'Task Change Event', 'Service Appointment Change Event'
                                                      , 'Return Order Change Event', 'Outgoing Email Relation', 'Outgoing Email', 'Order Change Event', 'Opportunity Contact Role Change Event', 
                                                        'Opportunity Change Event', 'Open Activity', 'Maintenance Plan Change Event', 'Lead Change Event', 'Event Change Event', 'Event', 'Email Status', 
                                                        'Contract Change Event', 'Contact Change Event', 'Case Change Event', 'Campaign Member Change Event', 'Asset Change Event ', 'ActivityRecurrence2Exception',
                                                        'ActivityRecurrence2', 'Activity History', 'Account contact role change event' };
        if(filterString=='' || filterString== null){
            String objName;
            string apiName;
            Integer i = 1;
            Schema.DescribeSObjectResult describe = Contact.sObjectType.getDescribe();
            for (Schema.ChildRelationship cr : describe.getChildRelationships()){
                //system.debug('Child Object Name '+i+' === '+cr.getChildSObject());
                system.debug('cr>>>>>'+cr);
                apiName = cr.getChildSObject().getDescribe().getName();// API Name of an object
                //System.debug('ObjName == '+objName);
                //apiName = string.valueOf(cr.getChildSObject().sObjectType.getDescribe());
                objName = cr.getChildSObject().getDescribe().getLabel(); // Label of an object
                
                //System.debug('APIName == '+apiName);
                
                //conChildObjNames.add(objName,apiName);
                // if(options.size()<4){
                if(!ObjApiName.contains(apiName) && !notSupportedObj.contains(ObjName)){
                    ObjApiName.add(apiName);
                    options.add( new conChildObjNames( objName, apiName ) );
                }
                // }
                
                //returnRelatedList.add(objName);
                
            }
            //system.debug('options>>>>>>>>>'+options);
            for(conChildObjNames opt : options){
                
                // system.debug('options>>>>>>>>>'+opt);
                
            }
            return options;
        }
        if(filterString!=''){
            String objName;
            string apiName;
            Integer i = 1;
            Schema.DescribeSObjectResult describe = Contact.sObjectType.getDescribe();
            for (Schema.ChildRelationship cr : describe.getChildRelationships()){
                //system.debug('Child Object Name '+i+' === '+cr.getChildSObject());
                apiName = cr.getChildSObject().getDescribe().getName();// API Name of an object
                //System.debug('ObjName == '+objName);
                //apiName = string.valueOf(cr.getChildSObject().sObjectType.getDescribe());
                objName = cr.getChildSObject().getDescribe().getLabel(); // Label of an object
                
                //System.debug('APIName == '+apiName);
                
                //conChildObjNames.add(objName,apiName);
                options.add( new conChildObjNames( objName, apiName ) );
                //returnRelatedList.add(objName);
            }
            
            List<conChildObjNames> listFiltered = new List<conChildObjNames>();
            for(conChildObjNames op:options){
                if(op.label.toLowerCase().contains(filterString.toLowerCase())){
                    if(listFiltered.size()<4){
                        listFiltered.add( new conChildObjNames( op.label, op.value ) );
                    }
                    
                    
                }
            }
            system.debug('Filtered List==>'+listFiltered);
            return listFiltered;
        }
        
        return null;
    }
    
    @AuraEnabled
    public static String mergeChildRedcords(List<String> conIds, List<String> sObjectChildAPIs, Id parentId) {
        String resultStatus;
        String query = null;
        system.debug('conIds=====>'+conIds+'====conIds.size()==='+conIds.size());
        system.debug('sObjectChildAPIs=====>'+sObjectChildAPIs);
        system.debug('parentId=====>'+parentId);
        List<Id> contactIdList=new List<Id>();
        for(Integer i=0;i<conIds.size();i++){
            contactIdList.add(conIds[i].split('check_')[1]);
        }
        
        //List<Id> contactIdList=conIds;
        
        //String contactId = '0032v000030Wh1BAAS';	
        List<SObject> sObjectListData = new List<SObject>();
        List<SObject> sObjectListUpdate = new List<SObject>();
		        
        for(String objName : sObjectChildAPIs) {
            for(Id conId:contactIdList){
                
                SObjectType objType = Schema.getGlobalDescribe().get(objName);
                Map<String,Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
                for (Schema.SObjectField fieldName: fieldMap.values()){
                    
                    schema.DescribeFieldResult fieldDefinition = fieldName.getDescribe();
                    if(fieldDefinition.getType() == schema.DisplayType.REFERENCE && String.valueOf(fieldDefinition.getReferenceTo().get(0)) == 'Contact'){
                        System.debug('=======111==== '+conId);
                        System.debug('=======111==== '+fieldName);
                        query = 'SELECT Id, ' + fieldName + ' FROM ' + objName + ' WHERE ' + fieldName + ' = \'' + conId + '\'';
                        sObjectListData = (Database.query(query));
                         System.debug('=======sObjectListData116==== '+sObjectListData);
                        for(Sobject sObjData : sObjectListData){
                            ID sObjRecordId = sObjData.id;
                            system.debug('sObjRecordId=====>'+sObjRecordId);

                            
                            sObject obj = Schema.getGlobalDescribe().get(objName).newSObject();
                            obj.put('Id', sObjRecordId);
                            obj.put(fieldName, parentId);
                            sObjectListUpdate.add(obj);
                        }
                    }
                }
            }    
        }
        system.debug('sObjectListUpdate=====>'+sObjectListUpdate);
        
        if(sObjectListUpdate != null){
            try{
                update sObjectListUpdate;
            	resultStatus='SUCCESS';
            }catch(DmlException e) {
                resultStatus='Failure';
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
         }
         
         return resultStatus;
        
    }
    
    public class conChildObjNames{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        
        public conChildObjNames( String label, String value ) {
            this.label = label;
            this.value = value;
        }
    }
}