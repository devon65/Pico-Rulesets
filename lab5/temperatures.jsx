'use strict';
// import React from 'react';

// import axios from 'axios';

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
  
    ListItem(props) {
        return <li>{props.value}</li>;
    }

    TemperatureEntryList(props) {
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
        // fetch('http://xkcd.com/info.0.json', {
        //     method: 'GET',
        //     headers: {
        //       'Content-Type': 'application/json'
        //     }
        //   })
        // .then((response) => {
        //     return response.json();
        // })
        // .then((data) => {
        //     console.log(data);
        // });
        fetch('http://xkcd.com/info.0.json', {
            method: 'GET',
            headers: {
                'Access-Control-Allow-Credentials' : true,
                'Access-Control-Allow-Origin':'*',
                'Access-Control-Allow-Methods':'GET',
                'Access-Control-Allow-Headers':'application/json',
              },
        })
        // this.setState({temperatureEntries: this.TEMP_ENTRIES_MOCK})
        
    }
  
    render() {
        return(
            <div>
                <h1>Temperature Entries:</h1>
                <h2>yas</h2>
            </div>
        );
    }
  }
  
  ReactDOM.render(
    <TemperatureReadings />,
    document.getElementById('root')
  );
  