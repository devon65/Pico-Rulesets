import React from 'react';
import logo from './logo.svg';
import './App.css';
import axios from 'axios';

const TEMP_CHANNEL = '4JrzxFKL7y71kYTFptZ46P'
const SKY_QUERY_BASE = 'http://localhost:8080/sky/cloud/'
const SKY_EVENT_BASE = 'http://localhost:8080/sky/event/'
const TEMP_ENTRY_QUERY = '/temperature_store/temperatures'
const TEMPT_VIOLATION_QUERY = '/temperature_store/threshold_violations'
const CUR_TEMP_QUERY = '/temperature_store/current_temperature'
const POST_PROFILE_UPDATE = '/5/sensor/profile_updated'
const PROFILE_INFO_QUERY = '/sensor_profile/profile_info'

function ListItem(props) {
  return <li>{`${props.value[1]} @ ${props.value[0]}`}</li>;
}

function TemperatureEntryList(props) {
  const entries = props.entries;
  const listItems = entries.map((entry) =>
      <ListItem key={entry[0]}
              value={entry} />

  );
  return (
      <ul>
      {listItems}
      </ul>
  );
}

class TemperatureReadings extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        currentTemperature: 80,
        temperatureEntries: [],
        temperatureViolations: []
      };
  
    //   this.handleInputChange = this.handleInputChange.bind(this);
    }

    componentDidMount() {
      this.fetchCurrentTemperature()
      this.fetchTemperatureEntries()
      this.fetchTemperatureViolations()
      this.timerID = setInterval(
        () => this.fetchTemperatureEntries(),
        10000
      );
      this.violationTimer = setInterval(
        () => this.fetchTemperatureViolations(),
        10000
      );
      this.curTempTimer = setInterval(
        () => this.fetchCurrentTemperature(),
        10000
      )
    }
    
    componentWillUnmount() {
        clearInterval(this.timerID);
        clearInterval(this.violationTimer);
    }

    fetchCurrentTemperature(){
      axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + CUR_TEMP_QUERY)
      .then(response => this.setState({ currentTemperature: response.data }))
      // .then(response => console.log(response));
    }

    fetchTemperatureEntries(){
        axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + TEMP_ENTRY_QUERY)
        .then(response => this.setState({ temperatureEntries: response.data.reverse() }));
    }

    fetchTemperatureViolations(){
        axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + TEMPT_VIOLATION_QUERY)
        .then(response => this.setState({ temperatureViolations: response.data.reverse() }));
    }
  
    render() {
        return(
            <div>
              <h1>Current Temperature: {this.state.currentTemperature}</h1>
              <br/>
              <h1>Violation Entries:</h1>
              <TemperatureEntryList entries={this.state.temperatureViolations}/>
              <h1>Temperature Entries:</h1>
              <TemperatureEntryList entries={this.state.temperatureEntries}/>
            </div>
        );
    }
  }  

  class ProfileInfo extends React.Component{
    constructor(props) {
      super(props);
      this.state = {
        sensorLocation: "",
        sensorName: "",
        temperatureThreshold: 0,
        notifyNumber: ""
      };

      this.fetchProfileInfo = this.fetchProfileInfo.bind(this)
    }

    componentDidMount(){
      this.fetchProfileInfo()
    }

    updateProfile(props){
      console.log(props)
      this.setState({ sensorLocation: props.location })
      this.setState({ sensorName: props.name })
      this.setState({ temperatureThreshold: props.temperature_threshold })
      this.setState({ notifyNumber: props.notify_number })
    }

    fetchProfileInfo() {
      axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + PROFILE_INFO_QUERY)
        .then(response => {
          this.updateProfile(response.data)
        });
    }

    render() {
      return (
        <div>
          <h1>Current Profile</h1>
          <h3>Sensor Location: {this.state.sensorLocation}</h3>
          <h3>Sensor Name: {this.state.sensorName}</h3>
          <h3>Temperature Threshold: {this.state.temperatureThreshold}</h3>
          <h3>Notify Number: {this.state.notifyNumber}</h3>
          <button onClick={this.fetchProfileInfo}>Refresh</button>
        </div>
      )
    }
  }

  class ProfileForm extends React.Component{
    constructor(props) {
      super(props);
      this.state = {
        sensorLocation: "Home",
        sensorName: "Sensor",
        temperatureThreshold: 80,
        notifyNumber: "123456789"
      };
      this.handleInputChange = this.handleInputChange.bind(this);
    }

    handleInputChange(event) {
      const target = event.target;
      const value = target.value;
      const name = target.name;

      this.setState({
        [name]: value
      });
    }

    resetForm(){
        this.setState({sensorLocation: ""})
        this.setState({sensorName: ""})
        this.setState({temperatureThreshold: 80})
        this.setState({notifyNumber: ""})
    }

    postUpdateProfile = () => {
      axios.post(SKY_EVENT_BASE + TEMP_CHANNEL + POST_PROFILE_UPDATE, null, { params: {
        "location":this.state.sensorLocation,
        "name": this.state.sensorName,
        "temperature_threshold": this.state.temperatureThreshold,
        "notify_number": this.state.notifyNumber
      }})
      .then(response => {
        this.resetForm()
      })
      .catch(err => console.warn(err));
    }

    render() {
      return (
        <div>
          <h1>Update Profile</h1>
            <form>
              <label>
                Sensor Location: 
                <input
                  name="sensorLocation"
                  type="string"
                  value={this.state.sensorLocation}
                  onChange={this.handleInputChange} />
              </label>
              <br /><br />
              <label>
                Sensor Name:
                <input
                  name="sensorName"
                  type="string"
                  value={this.state.sensorName}
                  onChange={this.handleInputChange} />
              </label>
              <br /><br />
              <label>
                Temperature Threshold:
                <input
                  name="temperatureThreshold"
                  type="number"
                  value={this.state.temperatureThreshold}
                  onChange={this.handleInputChange} />
              </label>
              <br /><br />
              <label>
                Notify Number: 
                <input
                  name="notifyNumber"
                  type="string"
                  value={this.state.notifyNumber}
                  onChange={this.handleInputChange} />
              </label>
            </form>
            <br />
            <button onClick={this.postUpdateProfile}>Submit</button>
            <ProfileInfo/>
          </div>
        );
    }
  }

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      displayList: true
    };
  }

  swapDisplay = () => {
    this.setState({displayList: !this.state.displayList})
  }

    render() {
      return (
        <div className="App">
          <br />
          <button onClick={this.swapDisplay}>{this.state.displayList? "View Profile" : "View Entries"}</button>
          {this.state.displayList? 
            <TemperatureReadings/> :
            <ProfileForm/>
          }
        </div>
      );
    }
}

export default App;
