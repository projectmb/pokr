import ReactOnRails from 'react-on-rails';

import Room from '../containers/Room';
import Board from '../components/Board';
import { Shared } from '../components/Shared';

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  Room, Board
});
