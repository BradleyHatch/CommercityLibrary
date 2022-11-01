import React from 'react';
import PropTypes from 'prop-types';
import shortid from 'shortid';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/accordian.scss';


class Accordian extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      open: false
    };
  }

  _handleToggle() {
    this.setState({open: !this.state.open});
  }

  _renderRow(row) {
    return(
      <div className="accordian__row" key={shortid.generate()}>
        {row}
      </div>
    );
  }

  _renderRows() {
    return this.props.rows.map(row => {
      return this._renderRow(row);
    });
  }

  render() {
    return(
      <div className="accordian">
        <div
          className={
            this.props.showHeaderDivider
            ? "accordian__row accordian__row--header accordian__row--with-divider"
            : "accordian__row accordian__row--header"
          }
          onClick={this._handleToggle}
        >
          { this.props.headerContent }
        </div>
        <div className="accordian__content">
          {this.state.open ? this._renderRows() : null}
        </div>
      </div>
    );
  }
}

Accordian.propTypes = {
  headerContent: PropTypes.node,
  rows: PropTypes.array,
  showHeaderDivider: PropTypes.bool
};

Accordian.defaultProps = {
  headerContent: null,
  rows: [],
  showHeaderDivider: false
};

export default applyComponentDecorators(Accordian);
