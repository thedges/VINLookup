import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getVINDetails from '@salesforce/apex/PSVinLookupDetails.getVINDetails';
import getRecordVIN from '@salesforce/apex/PSVinLookupDetails.getRecordVIN';

export default class vinLookup extends LightningElement {
  @track details = [];
  @track vin;
  @track showSpinner = false;
  @api recordId;
  @api fieldName = '';

  ///////////////////////////////////////////////////////
  // method that is called on component initialization //
  //  - lookup VIN in record field of record           //
  //  - autoload VIN details if VIN # exists on record //
  ///////////////////////////////////////////////////////
  connectedCallback () {
    var self = this;

    // check if fieldName is provided in component configuration
    if (this.fieldName != null && this.fieldName.length > 0) {

      // invoke APEX method to retrieve VIN # from current record id  
      getRecordVIN ({
        recId: this.recordId,
        fieldName: this.fieldName,
      }).then (result => {
        console.log ('vin #=' + result);

        if (result != null && result.length > 0)
        {
          self.vin = result;

          // autoload details if VIN # exists on record
          self.getData();
        }
      });
    }
  }

  ////////////////////////////////////////////////////
  // method to invoke NHTSA VIN decode REST service //
  ////////////////////////////////////////////////////
  getData () {
    var self = this;
    self.details = [];

    self.showSpinner = true;

    // invoke APEX method to invoke NHTSA REST service
    console.log ('getting vin data...');
    getVINDetails ({
      vin: this.vin,
    })
      .then (result => {
        console.log ('vin details=' + result);
        self.showSpinner = false;

        // parse String response in to object
        const vinParams = JSON.parse (result);

        // check if Make is provided else assume lookup failed for VIN #
        if (vinParams.Make == null || vinParams.Make == '') {
          const event = new ShowToastEvent ({
            title: 'Warning!',
            message: 'VIN [' + self.vin + '] could not be found.',
            variant: 'warning',
          });
          this.dispatchEvent (event);
        } else {
          // build object for HTML template to be able to loop through and show parameters
          for (var key in vinParams) {
            self.details.push ({key: key, value: vinParams[key]});
          }
        }

        console.log ('details=' + JSON.stringify (self.details));
      })
      .catch (error => {
        console.log ('callout error ===> ' + JSON.stringify (error));
        self.showSpinner = false;
        const event = new ShowToastEvent ({
          title: 'Error!',
          message: error.body.message,
          variant: 'error',
        });
        this.dispatchEvent (event);
      });
  }

  handleChange (event) {
    if (event.type === 'change') {
      console.log ('event.detail=' + event.detail);
      console.log ('vin=' + event.detail.value);
    } else if (event.type === 'blur') {
      console.log ('vin=' + event.target.value);
      this.vin = event.target.value;
    }
  }

  clearData () {
    this.details = [];
    this.vin = '';
  }
}