import React from 'react';
import logo from './logo.svg';
import './App.css';
import axios from 'axios';

const TEMP_CHANNEL = '4JrzxFKL7y71kYTFptZ46P'
const SKY_QUERY_BASE = 'http://localhost:8080/sky/cloud/'
const TEMP_ENTRY_QUERY = '/temperature_store/temperatures'
const API = 'https://hn.algolia.com/api/v1/search?query=';
const DEFAULT_QUERY = 'redux';
const TEMP_ENTRIES_MOCK = [
    [
        "2020-02-27T04:04:02.052Z",
        68.34
    ],
    [
        "2020-02-27T04:04:14.025Z",
        68.34
    ],
    [
        "2020-02-27T04:04:27.515Z",
        68.34
    ],
    [
        "2020-02-27T04:04:39.553Z",
        68.34
    ],
    [
        "2020-02-27T04:04:52.731Z",
        68.34
    ]];

function ListItem(props) {
  return <li>{props.value}</li>;
}

function TemperatureEntryList(props) {
  const entries = props.entries;
  const listItems = entries.map((entry) =>
      <ListItem key={entry[0]}
              value={entry[1]} />

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
        this.timerID = setInterval(
          () => this.fetchTemperatureEntries(),
          10000
        );
      }
    
    componentWillUnmount() {
        clearInterval(this.timerID);
    }

    ProfileForm(props){
        return (
            <form>
              <label>
                Is going:
                <input
                  name="isGoing"
                  type="checkbox"
                  checked={this.state.isGoing}
                  onChange={this.handleInputChange} />
              </label>
              <br />
              <label>
                Number of guests:
                <input
                  name="numberOfGuests"
                  type="number"
                  value={this.state.numberOfGuests}
                  onChange={this.handleInputChange} />
              </label>
            </form>
          );
    }

    fetchTemperatureEntries(){
        // fetch(SKY_QUERY_BASE + TEMP_CHANNEL + TEMP_ENTRY_QUERY)
        // fetch(API + DEFAULT_QUERY)
        // .then(response => response.json())
        // .then(data => this.setState({ temperatureEntries: data }));
        axios.get(SKY_QUERY_BASE + TEMP_CHANNEL + TEMP_ENTRY_QUERY)
        .then(response => this.setState({ temperatureEntries: response.data }));
        
        // this.setState({temperatureEntries: this.TEMP_ENTRIES_MOCK})
        
    }
  
    render() {
        return(
            <div>
                <h1>Temperature Entries:</h1>
                <TemperatureEntryList entries={this.state.temperatureEntries}/>
            </div>
        );
    }
  }  

function App() {
  return (
    <div className="App">
      <TemperatureReadings/>
    </div>
  );
}

export default App;
