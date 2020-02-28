import React from 'react';
import logo from './logo.svg';
import './App.css';
import axios from 'axios';

const TEMP_CHANNEL = '4JrzxFKL7y71kYTFptZ46P'
const SKY_QUERY_BASE = 'http://localhost:8080/sky/cloud/'
const SKY_EVENT_BASE = 'http://localhost:8080/sky/event/'
const TEMP_ENTRY_QUERY = '/temperature_store/temperatures'
const TEMPT_VIOLATION_QUERY = '/temperature_store/threshold_violations'
const POST_PROFILE_UPDATE = '/5/sensor/profile_updated'

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
      }
    
    componentWillUnmount() {
        clearInterval(this.timerID);
        clearInterval(this.violationTimer);
    }


    fetchTemperatureEntries(){
        axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + TEMP_ENTRY_QUERY)
        .then(response => this.setState({ temperatureEntries: response.data }));
    }

    fetchTemperatureViolations(){
        axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + TEMPT_VIOLATION_QUERY)
        .then(response => this.setState({ temperatureViolations: response.data }));
    }
  
    render() {
        return(
            <div>
              <h1>Violation Entries:</h1>
              <TemperatureEntryList entries={this.state.temperatureViolations}/>
              <h1>Temperature Entries:</h1>
              <TemperatureEntryList entries={this.state.temperatureEntries}/>
            </div>
        );
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
      axios.get(SKY_EVENT_BASE + TEMP_CHANNEL + POST_PROFILE_UPDATE, null, { params: {
        "location":this.state.sensorLocation,
        "name": this.state.sensorName,
        "temperature_threshold": this.state.temperatureThreshold,
        "notify_number": this.state.notifyNumber
      }})
      .then(response => {
        this.resetForm()
        // response.status
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
            <button onClick={this.postUpdateProfile}>Submit</button>
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
